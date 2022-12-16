//
//  ContentModel.swift
//  LearningApp
//
//  Created by Christopher Ching on 2021-03-03.
//

import Foundation
import FirebaseFirestore
import FirebaseCore

class ContentModel: ObservableObject {
    
    let db = Firestore.firestore()
    
    // List of modules
    @Published var modules = [Module]()
    
    // Current module
    @Published var currentModule: Module?
    var currentModuleIndex = 0
    
    // Current lesson
    @Published var currentLesson: Lesson?
    var currentLessonIndex = 0
    
    // Current question
    @Published var currentQuestion: Question?
    var currentQuestionIndex = 0
    
    // Current lesson explanation
    @Published var codeText = NSAttributedString()
    var styleData: Data?
    
    // Current selected content and test
    @Published var currentContentSelected:Int?
    @Published var currentTestSelected:Int?
    
    
    init() {
        getLocalStyles()
        
        // get database modules
       getDatabaseModules()
        
    }
    
    // MARK: - Data methods
    
    func getDatabaseModules() {
        
        // Specify path
        let collection = db.collection("modules")
        
        // Get documents
        collection.getDocuments { snapshot, error in
            
            if error == nil && snapshot != nil {
                
                // Create an array for the modules
                var modules = [Module]()
                
                // Loop through the documents returned
                for doc in snapshot!.documents {
                    
                    // Create a new module instance
                    var m = Module()
                    
                    // Parse out the values from the document into the module instance
                    m.id = doc["id"] as? String ?? UUID().uuidString
                    m.category = doc["category"] as? String ?? ""
                    
                    // Parse the lesson content
                    let contentMap = doc["content"] as! [String:Any]
                    
                    m.content.id = contentMap["id"] as? String ?? ""
                    m.content.description = contentMap["description"] as? String ?? ""
                    m.content.image = contentMap["image"] as? String ?? ""
                    m.content.time = contentMap["time"] as? String ?? ""
                    
                    // Parse the test content
                    let testMap = doc["test"] as! [String:Any]
                    
                    m.test.id = testMap["id"] as? String ?? ""
                    m.test.description = testMap["description"] as? String ?? ""
                    m.test.image = testMap["image"] as? String ?? ""
                    m.test.time = testMap["time"] as? String ?? ""
                    
                    // Add it to our array
                    modules.append(m)
                }
                
                // Assign our modules to the published property
                DispatchQueue.main.async {
                    
                    self.modules = modules
                }
            }
            
        }
        
    }
    
//    func getDatabaseModules() {
//
//        let collection = db.collection("modules")
//
//        //get documents
//        collection.getDocuments { qSnap, error in
//            if let error {
//                print(error.localizedDescription)
//            } else if let qSnap {
//
//                var modules = [Module]()
//
//                for doc in qSnap.documents {
//
//                    //parse out the data from the document into variables
//
//                    // create a new module instance
//                    var m = Module()
//
//                    //parse out the values from the document into the module instance
//                    m.id = doc["id"] as? String ?? UUID().uuidString //you have to cast as a string cuz xcode dont know what type is coming out in the dic since its mixed type
//                    m.category = doc["category"] as? String ?? ""
//
//                    //parse the lesson content
//                    //since content is a custom type with properties, i have to dril deeper into it, so once i have a reference to it from the firebase then i match the properties one by one to the Module.Content model
//                    let contentMap = doc["content"] as? [String: Any] ?? [:] // i am grabbing the whole map( all keys on that map are strings, th evalue are string and ints so i have to use type Any [String:Any].....// i can also use as! and not optional coalese
//
//                    // match up the content properties with the documents filed's keys
//                    m.content.id = contentMap["id"] as? String ?? ""
//                    m.content.description = contentMap["description"] as? String ?? ""
//                    m.content.image = contentMap["image"] as? String ?? ""
//                    m.content.time = contentMap["time"] as? String ?? ""
//                    // we are ignoring the filed "count" because we are not using it and its not even in the model (Module.Content)
//
//                    //parse test content
//                    let testmap = doc["test"] as? [String: Any] ?? [:] // i can also use as? and use optional coalese like with contentMap
//
//                    m.test.id = testmap["id"] as? String ?? ""
//                    m.test.description = testmap["description"] as? String ?? ""
//                    m.test.image = testmap["image"] as? String ?? ""
//                    m.test.time = testmap["time"] as? String ?? ""
//
//                    //add it to our array
//                    modules.append(m)
//                }
//
//                // assign our modules to the published property
//                DispatchQueue.main.async {
//                    self.modules = modules
//                }
//
//            }
//        }
//
//    }
    
    func getLocalStyles() {
        
        // Parse the style data
        let styleUrl = Bundle.main.url(forResource: "style", withExtension: "html")
        
        do {
            
            // Read the file into a data object
            let styleData = try Data(contentsOf: styleUrl!)
            
            self.styleData = styleData
        }
        catch {
            // Log error
            print("Couldn't parse style data")
        }
        
    }
    
    // MARK: - Module navigation methods
    
    func beginModule(_ moduleid: String) {
        
        // Find the index for this module id
        for index in 0..<modules.count {
            
            if modules[index].id == moduleid {
            
                // Found the matching module
                currentModuleIndex = index
                break
            }
        }
        
        // Set the current module
        currentModule = modules[currentModuleIndex]
    }
    
    func beginLesson(_ lessonIndex:Int) {
        
        // Check that the lesson index is within range of module lessons
        if lessonIndex < currentModule!.content.lessons.count {
            currentLessonIndex = lessonIndex
        }
        else {
            currentLessonIndex = 0
        }
        
        // Set the current lesson
        currentLesson = currentModule!.content.lessons[currentLessonIndex]
        codeText = addStyling(currentLesson!.explanation)
    }
    
    func nextLesson() {
        
        // Advance the lesson index
        currentLessonIndex += 1
        
        // Check that it is within range
        if currentLessonIndex < currentModule!.content.lessons.count {
            
            // Set the current lesson property
            currentLesson = currentModule!.content.lessons[currentLessonIndex]
            codeText = addStyling(currentLesson!.explanation)
        }
        else {
            // Reset the lesson state
            currentLessonIndex = 0
            currentLesson = nil
        }
    }
    
    func hasNextLesson() -> Bool {
        
        guard currentModule != nil else {
            return false
        }
        
        return (currentLessonIndex + 1 < currentModule!.content.lessons.count)
    }
    
    func beginTest(_ moduleId: String) {
        
        // Set the current module
        beginModule(moduleId)
        
        // Set the current question index
        currentQuestionIndex = 0
        
        // If there are questions, set the current question to the first one
        if currentModule?.test.questions.count ?? 0  > 0 {
            currentQuestion = currentModule!.test.questions[currentQuestionIndex]
            
            // Set the question content
            codeText = addStyling(currentQuestion!.content)
        }
    }
    
    func nextQuestion() {
        
        // Advance the question index
        currentQuestionIndex += 1
        
        // Check that it's within the range of questions
        if currentQuestionIndex < currentModule!.test.questions.count {
            
            // Set the current question
            currentQuestion = currentModule!.test.questions[currentQuestionIndex]
            codeText = addStyling(currentQuestion!.content)
        }
        else {
            // If not, then reset the properties
            currentQuestionIndex = 0
            currentQuestion = nil
        }
        
    }
    
    // MARK: - Code Styling
    
    private func addStyling(_ htmlString: String) -> NSAttributedString {
        
        var resultString = NSAttributedString()
        var data = Data()
        
        // Add the styling data
        if styleData != nil {
            data.append(styleData!)
        }
        
        // Add the html data
        data.append(Data(htmlString.utf8))
        
        // Convert to attributed string
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            
            resultString = attributedString
        }
        
        return resultString
    }
}
