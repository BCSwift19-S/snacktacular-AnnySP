//
//  Photo.swift
//  Snacktacular
//
//  Created by Anny Shan on 4/22/19.
//  Copyright © 2019 Anny Shan. All rights reserved.
//

import Foundation
import Firebase

class Photo {
    var image: UIImage
    var description: String
    var postBy: String
    var date: Date
    var documentUUID: String
    var dictionary: [String:Any] {
        return ["description": description, "postBy": postBy, "date": date]
    }
    
    init(image: UIImage, description: String, postBy: String, date: Date, documentUUID: String) {
        self.image = image
        self.description = description
        self.postBy = postBy
        self.date = date
        self.documentUUID = documentUUID
    }
    
    convenience init() {
        let postBy = Auth.auth().currentUser?.email ?? "unknown user"
        self.init(image: UIImage(), description: "", postBy: postBy, date: Date(), documentUUID: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let description = dictionary["description"] as! String? ?? ""
        let postBy = dictionary["postBy"] as! String? ?? ""
        let date = dictionary["date"] as! Date? ?? Date()
        self.init(image: UIImage(), description: description, postBy: postBy, date: date, documentUUID: "")
    }
    
    func saveData(spot: Spot, completed: @escaping (Bool) -> () ) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        guard let photoData = self.image.jpegData(compressionQuality: 0.5) else {
            print("***** ERROR: could not convert image to data format.")
            return completed(false)
        }
        documentUUID = UUID().uuidString
        let storageRef = storage.reference().child(spot.documentID).child(self.documentUUID)
        storageRef.putData(photoData)
        let uploadTask = storageRef.putData(photoData)
        uploadTask.observe(.success) { (snapshot) in
            let dataToSave = self.dictionary
            let ref = db.collection("spots").document(spot.documentID).collection("photos").document(self.documentUUID)
            ref.setData(dataToSave) { (error) in
                if let error = error {
                    print("*** ERROR: updating document \(self.documentUUID) in spot \(spot.documentID) \(error.localizedDescription)")
                    completed(false)
                } else {
                    print("^^^ Document updated with ref ID \(ref.documentID)")
                    completed(true)
                }
            }
        }
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("***** ERROR: upload task for file \(self.documentUUID) failed, in spot \(spot.documentID)")
            }
            return completed(false)
        }
    }
}
