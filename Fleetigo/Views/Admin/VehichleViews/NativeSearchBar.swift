//import SwiftUI
//
//
//struct NativeSearchBar: UIViewControllerRepresentable {
//    @Binding var text: String
//    
//    class Coordinator: NSObject, UISearchBarDelegate {
//        @Binding var text: String
//        
//        init(text: Binding<String>) {
//            self._text = text
//        }
//        
//        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//            text = searchText
//            print("Search bar text changed to: \(searchText)") // Debug print
//        }
//        
//        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//            searchBar.resignFirstResponder()
//        }
//    }
//    
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(text: $text)
//    }
//    
//    func makeUIViewController(context: Context) -> UIViewController {
//        let searchController = UISearchController(searchResultsController: nil)
//        searchController.searchBar.delegate = context.coordinator
//        searchController.searchBar.placeholder = "Search by Vehicle Number"
//        searchController.obscuresBackgroundDuringPresentation = false
//        
//        searchController.searchBar.backgroundImage = UIImage()
//        searchController.searchBar.backgroundColor = .clear
//        
//        let viewController = UIViewController()
//        viewController.view.addSubview(searchController.searchBar)
//        searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            searchController.searchBar.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
//            searchController.searchBar.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
//            searchController.searchBar.topAnchor.constraint(equalTo: viewController.view.topAnchor),
//            searchController.searchBar.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
//        ])
//        
//        return viewController
//    }
//    
//    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
//        if let searchBar = (uiViewController.children.first as? UISearchController)?.searchBar {
//            searchBar.text = text
//            searchBar.backgroundImage = UIImage()
//            searchBar.backgroundColor = .clear
//        }
//    }
//}

import SwiftUI

struct NativeSearchBar: UIViewControllerRepresentable {
    @Binding var text: String
    
    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            self._text = text
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(text: $text)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = context.coordinator
        searchController.searchBar.placeholder = "Search by License Plate"
        searchController.obscuresBackgroundDuringPresentation = false
        
        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.backgroundColor = .clear
        
        let viewController = UIViewController()
        viewController.view.addSubview(searchController.searchBar)
        searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchController.searchBar.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            searchController.searchBar.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            searchController.searchBar.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            searchController.searchBar.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let searchBar = (uiViewController.children.first as? UISearchController)?.searchBar {
            searchBar.text = text
            searchBar.backgroundImage = UIImage()
            searchBar.backgroundColor = .clear
        }
    }
}
