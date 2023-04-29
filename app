import Foundation
import Firebase
import SwiftUI
import CoreGraphics
import SwiftUICharts

struct Content: View {
    @ObservedObject var authentication: Authentication
    @Binding var selectedMood: String?
    @Binding var selectedCategoryString: String



    var body: some View {
        MainView(authentication: authentication, selectedCategoryString: $selectedCategoryString)
    }
}

struct Homepage: View {
    @StateObject var viewModel = GoalsViewModel()
    @ObservedObject var authentication: Authentication
    @State var show = false
    @State var docID = ""
    @State var txt = ""
    @State var trigger = ""
    @State var obsession = ""
    @State var compulsion = ""
    @State var difficultyLevel = 0
    @State var anxietyLevel = 0
    @State var thoughtsFeelings = ""
    @State var notes = ""
    @State var email = ""
    @State var userName: String = ""
    @Binding var selectedCategoryString: String
    @State private var showingEditView = false
    @State var quote: String = ""
    @State var author: String = ""
    @State var lastSeen: Date = Date()
    @State var isLoading: Bool = true
    @State var category: String = "happiness"
    @State var selectedDate: Date = Date()
    @State var goals: [Goal] = []
    let userID = Auth.auth().currentUser?.uid
    @State private var currentTab = 0
    @State private var selectedTab = 0
    @State private var mood: String = ""
    @State var nextRefreshDate: Date = Date()
    @State var likedQuotes: [Quote] = []
    @State private var showMoodCaptureView = false
    @State private var isShowingMoodCapture = false
    @State private var showFormSelector = false
    @State private var showAddGoalView = false
    @State private var goal = ""
    @State private var habits = ["Meditation", "Exercise", "Reading", "Eating Healthy", "Sleep", "Water Intake", "Gratitude Practice", "Journaling", "Spending Time Outdoors", "Decluttering", "General"]
    @State private var selectedHabit = 10
    @State var selectedGoal: Goal?

    @State var selectedMood: String?
    @State var isLiked: Bool = false
    
    @State private var needsCheckIn: Bool?

    
    let db = Firestore.firestore()
    
    struct Quote: Decodable {
        let quote: String
        let author: String
    }
    
    init(authentication: Authentication, selectedCategoryString: Binding<String>) {
        self.authentication = authentication
        self._selectedCategoryString = selectedCategoryString // Move this line before the usage of 'selectedCategoryString'
        self._userName = State(initialValue: userName)

        // refreshQuote(manualRefresh: true) // fetch a new quote whenever the view is initialized
        retrieveUserData()
    }


    
    func retrieveUserData() {
        let userID = Auth.auth().currentUser!.uid
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                self.authentication.userName = data?["name"] as? String ?? ""
            } else {
                print("Error retrieving user data: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .onAppear {
                        self.shouldCheckInMood { needsCheckIn in
                            self.needsCheckIn = needsCheckIn
                        }
                        if self.nextRefreshDate <= Date() {
                                                self.refreshQuote(forceRefresh: true)
                                                self.nextRefreshDate = Calendar.current.date(byAdding: .minute, value: 360, to: Date())!
                                            }                    }
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                                           LazyVStack(spacing: 20) {
                                               Text("Hello, \(authentication.userName)")
                                                   .font(.title)
                                               VStack(spacing: 20) {
                                                   if let needsCheckIn = self.needsCheckIn {
                                                           Text(needsCheckIn ? "How are you feeling today?" : "Take the time to check in your mood...")
                                                       } else {
                                                           // Handle the case where the value of needsCheckIn is not yet available
                                                       }
                                                   MoodSelectorView(selectedMood: $selectedMood, selectedCategoryString: $selectedCategoryString)
                                                   Divider()
                                QuoteView(quote: self.quote, author: self.author, isLoading: self.isLoading)

                                    HStack(alignment: .bottom) {
                                        Spacer()
                                        Button(action: {
                                            if self.isLiked {
                                                // "Unlike" button action
                                                if let index = self.likedQuotes.firstIndex(where: { $0.quote == self.quote && $0.author == self.author }) {
                                                    self.likedQuotes.remove(at: index)
                                                }
                                                self.deleteLikedQuotes(quote: self.quote, author: self.author)
                                            } else {
                                                // "Like" button action
                                                self.likedQuotes.append(Quote(quote: self.quote, author: self.author))
                                                self.saveLikedQuotes(quote: self.quote, author: self.author)
                                            }
                                            self.isLiked.toggle()
                                        }) {
                                            Image(systemName: self.isLiked ? "heart.fill" : "heart")
                                                .foregroundColor(self.isLiked ? Color.green : Color.gray)
                                        }
                                        
                                        Button(action: {
                                            // "Share" button action
                                            let quoteToShare = "\(quote) - \(author)"
                                            let appName = "Journal Journey"
                                            
                                            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400))
                                            let image = renderer.image { context in
                                                UIColor.white.setFill()
                                                context.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
                                                
                                                let quoteFont = UIFont.systemFont(ofSize: 24, weight: .bold)
                                                let appNameFont = UIFont.systemFont(ofSize: 16)
                                                let paragraphStyle = NSMutableParagraphStyle()
                                                paragraphStyle.alignment = .center
                                                
                                                let quoteAttributes: [NSAttributedString.Key: Any] = [
                                                    .font: quoteFont,
                                                    .foregroundColor: UIColor.black,
                                                    .paragraphStyle: paragraphStyle
                                                ]
                                                let quoteSize = quoteToShare.boundingRect(with: CGSize(width: 560, height: 280), options: [.usesLineFragmentOrigin], attributes: quoteAttributes, context: nil).size
                                                let quoteRect = CGRect(x: 20, y: 40, width: 560, height: quoteSize.height)
                                                quoteToShare.draw(in: quoteRect, withAttributes: quoteAttributes)
                                                
                                                let appNameAttributes: [NSAttributedString.Key: Any] = [
                                                    .font: appNameFont,
                                                    .foregroundColor: UIColor.gray,
                                                    .paragraphStyle: paragraphStyle
                                                ]
                                                let appNameRect = CGRect(x: 20, y: quoteRect.maxY + 20, width: 560, height: 20)
                                                appName.draw(in: appNameRect, withAttributes: appNameAttributes)
                                            }
                                            
                                            guard let pngData = image.pngData() else {
                                                return
                                            }
                                            
                                            let activityController = UIActivityViewController(activityItems: [pngData], applicationActivities: nil)
                                            UIApplication.shared.windows.first?.rootViewController?.present(activityController, animated: true, completion: nil)
                                        }) {
                                            Image(systemName: "square.and.arrow.up")
                                        }

                                        
                                        Button(action: {
                                            print("Refresh button pressed")
                                                self.refreshQuote(manualRefresh: true)                                        }) {
                                            Image(systemName: "arrow.clockwise")
                                        }

                                        
                                    }.padding(.trailing)
                                    
                                    Divider()
                                    
                                    ZStack(alignment: .top) {
                                        TabView(selection: self.$currentTab) {
                                            Home(isDisplayedInTabView: true, selectedMood: $selectedMood,selectedCategoryString: $selectedCategoryString).tag(0)
                                            Eder(calendar: Calendar.current, isDisplayedInTabView: true).tag(1)
                                        }
                                        .tabViewStyle(PageTabViewStyle())
                                        .frame(height: 300)
                                        
                                        TabBarView(currentTab: self.$currentTab)
                                    }
                                }
                            }
                        }
                        
//                    }
//                .sheet(isPresented: $isShowingMoodCapture) {
//                    MoodCaptureView(moodCaptureViewModel: MoodCaptureViewModel(),
//                                     selectedMood: $selectedMood,
//                                     selectedGoalTrigger: selectedGoal?.name) {
//                        self.selectedMood = nil // set selectedMood to nil when the MoodCaptureView is dismissed
//                    }


                }.sheet(isPresented: $showFormSelector) {
                        FormSelector(selectedMood: $selectedMood,selectedCategoryString: $selectedCategoryString, isPresented: self.$showFormSelector,
                                     db: self.db,
                                     userID: self.userID,
                                     authentication: self.authentication
                        )
                        
                    }
                    .sheet(isPresented: $showAddGoalView) {
                        AddGoalView(isPresented: $viewModel.showAddGoalView, selectedDate: $viewModel.selectedDate, habits: $viewModel.habits, selectedHabit: $viewModel.selectedHabit, viewModel: viewModel)
                            .presentationDetents([.medium])
                    }
                }
                .navigationBarItems(trailing: HStack {
                    Button(action: { self.showFormSelector = true }) {
                        Image(systemName: "pencil")
                    }
                    Button(action: {
                        self.showAddGoalView = true }) {
                            Image(systemName: "checkmark.circle")
                        }
                })
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    
    func shouldCheckInMood(completion: @escaping (Bool) -> Void) {
        var needsCheckIn = true
        let userID = Auth.auth().currentUser!.uid
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        db.collection("users").document(userID).collection("notes")
            .whereField("from", isEqualTo: "Mood")
            .whereField("timestamp", isGreaterThanOrEqualTo: startOfDay)
            .whereField("timestamp", isLessThan: endOfDay)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting mood note: \(error.localizedDescription)")
                    completion(needsCheckIn)
                    return
                }

                guard let querySnapshot = querySnapshot else {
                    print("Error getting mood note: querySnapshot was nil")
                    completion(needsCheckIn)
                    return
                }

                if let _ = querySnapshot.documents.first {
                    // Mood note exists for today
                    // Set the message to "Take the time to check in your mood..."
                    needsCheckIn = false
                } else {
                    // Mood note does not exist for today
                    // Set the message to "How are you feeling today?"
                    needsCheckIn = true
                }

                completion(needsCheckIn)
            }
    }


   
    func saveLikedQuotes(quote: String, author: String) {
        let db = Firestore.firestore()
        let userID = Auth.auth().currentUser!.uid
        
        db.collection("users").document(userID).collection("liked_quotes").addDocument(data: [
            "quote": quote,
            "author": author
        ]) { error in
            if let error = error {
                print("Error saving liked quote: \(error.localizedDescription)")
            } else {
                print("Liked quote saved successfully!")
            }
        }
    }

    func deleteLikedQuotes(quote: String, author: String) {
        let db = Firestore.firestore()
        let userID = Auth.auth().currentUser!.uid
        
        db.collection("users").document(userID).collection("liked_quotes")
            .whereField("quote", isEqualTo: quote)
            .whereField("author", isEqualTo: author)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting liked quotes: \(error.localizedDescription)")
                    return
                }
                
                guard let querySnapshot = querySnapshot else {
                    print("Error getting liked quotes: querySnapshot was nil")
                    return
                }
                
                if let document = querySnapshot.documents.first {
                    document.reference.delete { error in
                        if let error = error {
                            print("Error deleting liked quote: \(error.localizedDescription)")
                        } else {
                            print("Liked quote deleted successfully!")
                        }
                    }
                }
            }
    }

    
    func refreshQuote(manualRefresh: Bool = false, forceRefresh: Bool = false, categories: [String] = ["happiness"]) {
        let defaults = UserDefaults.standard
        
        if !manualRefresh {
            // Check if it is a new session or if a force refresh is required
            if defaults.object(forKey: "isFirstLaunch") == nil || forceRefresh {
                defaults.set(false, forKey: "isFirstLaunch")
            } else {
                // Check if the last refresh date is more than 24 hours ago
                if let lastRefreshDate = defaults.object(forKey: "lastRefreshDate") as? Date,
                   Date().timeIntervalSince(lastRefreshDate) < 24 * 60 * 60 {
                    // Don't refresh if it's been less than 24 hours
                    return
                }
            }
        }
        
        isLoading = true
        
        // Combine multiple categories into a single string separated by commas
        let category = categories.joined(separator: ",")
        
        let categoryParam = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: "https://api.api-ninjas.com/v1/quotes?category=\(categoryParam!)")!
        var request = URLRequest(url: url)
        request.setValue("Y7EWfCiqzyU6/NolUw1oDw==5Z3cbFgDOuNvVA3t", forHTTPHeaderField: "X-Api-Key")
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data else { return }
            do {
                let quoteData = try JSONDecoder().decode([Quote].self, from: data)
                self.quote = quoteData[0].quote
                self.author = quoteData[0].author
                self.isLoading = false
                print("New quote: \(self.quote)")
                
                if !manualRefresh {
                    // Save the refresh date to UserDefaults
                    defaults.set(Date(), forKey: "lastRefreshDate")
                }
            } catch {
//                self.showErrorAlert(title: "Error", message: "Could not fetch quote")
            }
        }
        
        task.resume()
    }


//        func showErrorAlert(title: String, message: String) {
//            DispatchQueue.main.async {
//                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
//            }
//        }
    }
struct TabBarView: View {
    @Binding var currentTab: Int
    @Namespace var namespace
    
    var tabBarOptions: [String] = ["Recent Journal Entry", "Daily Goals"]
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(zip(self.tabBarOptions.indices, self.tabBarOptions)), id: \.0, content: {
                        index, name in
                        TabBarItem(currentTab: self.$currentTab, namespace: namespace.self, tabBarItemName: name, tab: index)
                    })
                }
                .padding(.horizontal)
                .frame(width: geometry.size.width)
            }
            .background(Color.white)
            .frame(height: 0)
            .alignmentGuide(.leading) { d in
                if geometry.size.width > UIScreen.main.bounds.width {
                    return d[.leading]
                } else {
                    return (UIScreen.main.bounds.width - geometry.size.width) / 2
                }
            }
            .alignmentGuide(.trailing) { d in
                if geometry.size.width > UIScreen.main.bounds.width {
                    return d[.trailing]
                } else {
                    return -(UIScreen.main.bounds.width - geometry.size.width) / 2
                }
            }
        }
    }
}


struct TabBarItem: View {
    @Binding var currentTab: Int
    let namespace: Namespace.ID
    var tabBarItemName: String
    var tab: Int
    
    var body: some View {
        Button {
            self.currentTab = tab
        } label: {
            VStack {
                Spacer()
                Text(tabBarItemName)
                if currentTab == tab {
                    Color.black
                        .frame(height: 2)
                        .matchedGeometryEffect(id: "underline", in: namespace, properties: .frame)
                } else {
                    Color.gray.opacity(0.3)
                        .frame(height: 2)
                }
            }
            .animation(.spring(), value: self.currentTab)
        }
        .buttonStyle(.plain)
    }
}



struct QuoteView: View {
    let quote: String
    let author: String
    let isLoading: Bool
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...", value: 0.0, total: 1.0)
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Text("“" + quote + "”")
                    .foregroundColor(.black)
                    .padding()
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 0, maxWidth: .infinity)
                
                Text("By " + author)
                    .foregroundColor(.black)
                    .padding()
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
        }
    }
}


import SwiftUI

struct CategoryPickerView: View {
    @State private var selectedCategory = "happiness"
    let categories = ["happiness", "inspirational", "success", "life", "love", "motivational", "friendship", "positive", "famous"]

    var body: some View {
        VStack {
            Text("Select a category:")
                .font(.headline)
            Picker("Category", selection: $selectedCategory) {
                ForEach(categories, id: \.self) {
                    Text($0.capitalized)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}




