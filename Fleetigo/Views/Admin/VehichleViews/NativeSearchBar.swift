// SearchBar.swift
import SwiftUI
import UIKit

struct NativeSearchBar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = "Search" // Customizable placeholder

    class Coordinator: NSObject, UISearchBarDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            text = searchText
        }

        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
        
        // Optional: Clear text when cancel button is clicked
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = "" // Clear the text
            text = ""           // Update the binding
            searchBar.resignFirstResponder()
            searchBar.showsCancelButton = false // Hide cancel button after click
        }

        // Optional: Show cancel button when editing begins
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            searchBar.showsCancelButton = true
        }

        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            // Optionally hide cancel button if text is empty, or always hide
            if searchBar.text?.isEmpty ?? true {
                 searchBar.showsCancelButton = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = placeholder
        searchBar.returnKeyType = .search // Changed to .search for a more standard search action
        searchBar.enablesReturnKeyAutomatically = false // Keep false if you want return always enabled

        // --- Customization to remove background/border ---
        searchBar.searchBarStyle = .minimal // This makes the background transparent

        // For even more control (if .minimal isn't enough or you want a custom background color):
        // 1. Remove the default background image
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        
        // 2. Make the search field background transparent or a custom color
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = UIColor.clear // Or your desired background color for the text field itself
            // textField.layer.cornerRadius = 10 // Optional: if you want rounded corners for the text field
            // textField.clipsToBounds = true    // Optional: if using cornerRadius
            
            // Customize text field appearance (optional)
            // textField.textColor = .label // Adapts to light/dark mode
            // textField.tintColor = .systemBlue // Cursor color
            // You can also set placeholder text color here if needed
            // let placeholderAttributes = [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
            // textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: placeholderAttributes)
        }
        // --- End Customization ---

        return searchBar
    }

    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
        uiView.placeholder = placeholder // Ensure placeholder updates if it's dynamic
    }
}

// MARK: - Preview
struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SearchBar(text: .constant(""), placeholder: "Search Items")
                .padding()
                .background(Color.gray.opacity(0.1)) // So you can see the search bar area

            SearchBar(text: .constant("Sample Text"), placeholder: "Search Products")
                .padding()
                .background(Color.yellow.opacity(0.2))
        }
    }
}
