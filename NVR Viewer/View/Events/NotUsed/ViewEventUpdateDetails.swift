//
//  ViewEventUpdate.swift
//  NVR Viewer
//
//  Created by Matthew Ehrhart on 3/15/24.
//

import SwiftUI
import SwiftData

struct ViewEventUpdate: View {
    
    @Query var containers: [ImageContainer]
    @Environment(\.modelContext) var context
    
    let eps: EndpointOptions
    //let tmp: EndpointOptions
    var body: some View {
        
        ForEach(containers, id: \.self){ container in
//            Text("\(container.label!)")
            Spacer()
                .onAppear(){
                    
                    do {
                        
                        //part 1
                        var arrayEPS = try JSONDecoder().decode([EndpointOptions].self, from: container.endPoints!)
                        arrayEPS.append(self.eps)
                        
                        //part 2
                        var jsonObjectEPS: Data?
                        do {
                            jsonObjectEPS = try JSONEncoder().encode(arrayEPS)
                        } catch(let error){
                            print(error)
                        }
                        
                        //part 3
                        container.endPoints = jsonObjectEPS
                        //print(arrayEPS)
                    } catch {
                        print("ERROR MESSAGE ------------------->")
                    }
                }
        }
    }
    
    init(name: String, eps: EndpointOptions ) {
        _containers = Query(filter: #Predicate<ImageContainer> { ic in 
            //ic.name == name
            ic.name.contains(name)
        }, sort: \ImageContainer.date)
         
        self.eps = eps
    }
    
    private func deserializeObject(object: Data?) ->  String{
        
        let jsonString = String(data: object!, encoding: .utf8)!
        return jsonString
    }
     
    func testMe(eps: EndpointOptions, container: ImageContainer){
        print("func testMe")
        print("EPS ----------------------------------")
        print(eps)
        print("ImageContainer ----------------------------------")
        print(container)
    }
}

//#Preview {
//    ViewEventUpdate(frameTime: 1710541384.496615, eps: nil)
//        .modelContainer(for: ImageContainer.self)
//}
 
