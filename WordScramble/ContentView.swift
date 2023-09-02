//
//  ContentView.swift
//  WordScramble
//
//  Created by Phil Prater on 9/2/23.
//

import SwiftUI

struct ContentView: View {
    // Game state
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    // Alert state
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Enter your word", text: $newWord)
                        .textInputAutocapitalization(.never)
                }
                
                Section {
                    ForEach(usedWords, id:\.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                    }
                }
            }
            .navigationTitle(rootWord)
            .onSubmit(addNewWord)
            .onAppear(perform: startGame) // this is how we run code when a view comes into existence.
            .alert(errorTitle, isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    func addNewWord() {
        // lowercase and trim the word, to make sure we don't add duplicate words
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // exit if the remaining string is empty
        guard answer.count > 0 else {
            wordError(title: "Empty word", message: "Actually enter a word")
            return
        }
        
        // exit if the user entered the prompt word
        guard isOriginal(word: answer) else {
            wordError(title: "Word used already", message: "Be more original")
            return
        }

        // exit if the word has letters not in the prompt
        guard isPossible(word: answer) else {
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!")
            return
        }

        // exit if the user entered a word that's not a word in English
        guard isReal(word: answer) else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            return
        }
        
        withAnimation {
            usedWords.insert(answer, at: 0)
        }
        newWord = ""
    }
    
    func startGame() {
        // 1. Find filepath (URL) for start.txt in the app bundle
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            // 2. Load start.txt into a string
            if let startWords = try? String(contentsOf: startWordsURL) {
                // 3. Split the string up into an array of strings, splitting on linebreaks
                let allWords = startWords.components(separatedBy: .newlines)
                
                // 4. Pick one random word, with "silkworm" as a reasonable default
                rootWord = allWords.randomElement() ?? "silkworm"
                
                // If we're here, everything worked, we can return
                return
            }
        }
        
        // If we're *here* something is VERY wrong - trigger a crash and report the error
        fatalError("Could not load start.txt from bundle.")
    }
    
    // check if the entered word is just the original prompt word
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    // Check if the user's input is a word that can be made from the random prompt word.
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        
        return true
    }
    
    // Verify that user entry is an actual word in English
    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        // NSNotFound is a special value that means the word is actually okay.
        // we'll actually get a misspelledRange that's an NSRange
        return misspelledRange.location == NSNotFound
    }
    
    // Set alert values and show it.
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
