import Foundation

struct Question: Identifiable {
    let id = UUID()
    let text: String
    let options: [String]
    let correctAnswerIndex: Int
}

class QuizManager: ObservableObject {
    @Published var questions: [Question]
    @Published var currentQuestionIndex = 0
    @Published var score = 0
    @Published var quizCompleted = false
    
    init() {
        // Sample questions
        self.questions = [
            Question(
                text: "What programming language is used to develop iOS apps?",
                options: ["Java", "Swift", "C#", "Python"],
                correctAnswerIndex: 1
            ),
            Question(
                text: "Which company created Swift?",
                options: ["Google", "Apple", "Microsoft", "Facebook"],
                correctAnswerIndex: 1
            ),
            Question(
                text: "What framework is used to create UI in modern iOS apps?",
                options: ["UIKit", "SwiftUI", "React Native", "Flutter"],
                correctAnswerIndex: 1
            ),
            Question(
                text: "What year was Swift first introduced?",
                options: ["2010", "2012", "2014", "2016"],
                correctAnswerIndex: 2
            )
        ]
    }
    
    func checkAnswer(_ selectedIndex: Int) {
        let currentQuestion = questions[currentQuestionIndex]
        if selectedIndex == currentQuestion.correctAnswerIndex {
            score += 1
        }
        
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            quizCompleted = true
        }
    }
    
    func restartQuiz() {
        currentQuestionIndex = 0
        score = 0
        quizCompleted = false
    }
}