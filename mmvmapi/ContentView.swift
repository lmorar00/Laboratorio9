//
//  ContentView.swift
//  mmvmapi
//
//  Created by Luis Mora Rivas on 18/9/21.
//

import SwiftUI

struct Results: Codable {
    let videoCourses: [Courses]
}

struct Courses: Identifiable, Codable {
    let id = UUID()
    let name: String
    let bannerUrl: String
    let price: Int
    
    enum CodingKeys: String, CodingKey {
        case name
        case bannerUrl
        case price
    }
    
    // The Initializer function from Decodable
    init(from decoder: Decoder) throws {
        // 1. Container
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        name =  try values.decode(String.self, forKey: .name)
        bannerUrl = try values.decode(String.self, forKey: .bannerUrl)
        
        if let price = try values.decodeIfPresent(Int.self, forKey: .price) {
            self.price  = price
        } else {
            self.price = 0
        }
    }
}

class CoursesViewModel: ObservableObject {
    @Published var messages = "Message Inside the observable object"
    
    @Published var courses: [Courses] = [
        //.init(name: "Course1", bannerUrl: "http://localhost.com", price: 30),
        //.init(name: "Course2", bannerUrl: "http://localhost2.com", price: 50)
    ]
    
    func changeMessage() {
        self.messages = "New Message"
    }
    
    func fetchCourses() {
        guard let url = URL(string: "https://www.letsbuildthatapp.com/home.json") else {
            print("Your API end point is invalid")
            return
        }
        
        let request = URLRequest(url: url)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let _ = error {
                print("Invalid end point")
            }
            
            if let data = data,
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                let results = try! JSONDecoder().decode(Results.self, from: data)
                DispatchQueue.main.async {
                    self.courses = results.videoCourses
                }
            }
            
        }.resume()
    }
}

struct ContentView: View {
    @ObservedObject  var coursesVM = CoursesViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(self.coursesVM.courses) {course in
                    VStack {
                        HStack {
                            Text(course.name)
                            Text(String(course.price))
                        }
                        
                        if let bannerUrl = URL(string: course.bannerUrl) {
                            Image(systemName: "square.fill").data(url: bannerUrl)
                                .frame(width: 200.0, height: 100.0)
                                
                        }
                    }
                }
                
            }
            .navigationBarTitle("Courses")
            .navigationBarItems(trailing: Button(
                action: {
                    print("Fetching json data")
                    self.coursesVM.fetchCourses()
                },
                label: {
                    Text("Fetch Courses")
                }
            ))
        }
    }
}

extension Image {
    func data(url: URL) -> Self {
        if let data = try? Data(contentsOf: url) {
            guard let image = UIImage(data: data) else {
                return Image(systemName: "square.fill")
            }
            
            return Image(uiImage: image)
                .resizable()
        }
        return self
            .resizable()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
