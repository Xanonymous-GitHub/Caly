//
//  ViewController.swift
//  Calculator
//
//  Created by TeU on 2022/3/21.
//

import UIKit
import MathExpression

class ViewController: UIViewController {
    @IBOutlet var expressionLabel: UILabel!
    @IBOutlet var resultLabel: UILabel!
    
    /// Used to store formulas.
    /// Stored in an array, each number and calculation symbol will be separated.
    private final var _expressions: Array<String> = [] {
        didSet {
            var displayText = _expressions.joined(separator: " ")
            
            _mathOperatorDisplayDict.forEach { (displayChar, realOptr) in
                displayText = displayText.replacingOccurrences(of: realOptr, with: displayChar)
            }
            
            // Update UI for showing current formula.
            expressionLabel.text = displayText
        }
    }
    
    /// Mathematical operation sub-character comparison table,
    /// used to compare the symbols used by the buttons on the screen with the symbols of the actual operation.
    private final let _mathOperatorDisplayDict = [
        "+": "+",
        "-": "-",
        "×": "*",
        "÷": "/",
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        _resetFormula()
    }
    
    private func _addExpressionCell(cell: String) {
        let isNumber = cell.isNumber()
        
        if (isNumber) {
            // Ensure zero is not the first cell in expression.
            if (cell == "0" && _expressions.count == 0) {
                return
            }
            
            // Add numbers into the expression line.
            _expressions.append(cell)
            return
        }
        
        let lastCell = _expressions.last
        
        // We need to ensure the previous (last) cell in the expression line is a number
        if (lastCell?.isNumber() ?? false) {
            _expressions.append(cell)
        }
    }
    
    /// Zero the calculator, clear all formulas, reset the screen.
    private func _resetFormula() {
        _expressions.removeAll()
        resultLabel.text = "0"
    }
    
    private func _calculateFormulaResult() throws {
        if (_expressions.isEmpty) {
            return
        }
        
        if (_hasDivideZero()) {
            _resetFormula()
            throw "NaN"
        }
        
        let lastCell = _expressions.last
        
        // Check if it is a complete formula.
        // If the last cell of the formula is not a number, it is ignored.
        let formula = lastCell?.isNumber() ?? true ? _expressions.joined() : _expressions[..<(_expressions.endIndex - 1)].joined()
        
        let realExpression = try MathExpression(formula)
        let result = realExpression.evaluate()
        
        let resultWithoutPoint = Int(result)
        
        resultLabel.text = Double(resultWithoutPoint) == result ? String(resultWithoutPoint) : String(result)
        
        _expressions.removeAll()
    }
    
    private func _hasDivideZero() -> Bool {
        for (index, cell) in _expressions.enumerated() {
            if (cell == "/" && index != (_expressions.endIndex - 1) && _expressions[index + 1] == "0") {
                return true
            }
        }
        
        return false
    }
    
    /// "Touch up Inside" event handler for numeric buttons (0 ~ 9).
    @IBAction func onNumberClicked(_ sender: UIButton, forEvent event: UIEvent) {
        let clickedNumber = sender.configuration?.title
        
        // Since all possible `sender` of this function are pre-defined, which not have a nil title, so we can directly use `!` to destruct the Optinal.
        _addExpressionCell(cell: clickedNumber!)
    }
    
    /// "Touch up Inside" event handler for operator buttons (+, -, ×, ÷).
    @IBAction func onOperatorClicked(_ sender: UIButton, forEvent event: UIEvent) {
        let clickedNumber = sender.configuration?.title
        
        let realOperatorSymbol = _mathOperatorDisplayDict[clickedNumber!]
        
        // Since all operators are pre-defined in the dict, so there's impossible to have a nil situation.
        _addExpressionCell(cell: realOperatorSymbol!)
    }
    
    /// "Touch up Inside" event handler for the reset button (AC).
    @IBAction func onResetClicked(_ sender: UIButton, forEvent event: UIEvent) {
        _resetFormula()
    }
    
    /// "Touch up Inside" event handler for the calculate button (=).
    @IBAction func onCalculateClicked(_ sender: UIButton, forEvent event: UIEvent) {
        do {
            try _calculateFormulaResult()
        } catch {
            // TODO: implement the error handlers for calculation errors.
            print("NaN!")
            resultLabel.text = "NaN"
        }
    }
}

fileprivate extension String {
func isNumber() -> Bool {
    return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil && self.rangeOfCharacter(from: CharacterSet.letters) == nil
}}

extension String: Error {}
