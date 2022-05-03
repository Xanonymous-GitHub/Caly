//
//  ViewController.swift
//  Calculator
//
//  Created by TeU on 2022/3/21.
//

import UIKit
import MathExpression

fileprivate enum operation: String {
    case add = "+"
    case subtract = "-"
    case multiply = "×"
    case divide = "÷"
}

class ViewController: UIViewController {
    @IBOutlet var expressionLabel: UILabel!
    @IBOutlet var resultLabel: UILabel!
    @IBOutlet var resetButton: UIButton!
    
    @IBOutlet var addButton: UIButton!
    @IBOutlet var subtractButton: UIButton!
    @IBOutlet var multiplyButton: UIButton!
    @IBOutlet var divideButton: UIButton!
    
    private final var _currentValue: String?
    private final var _currentOperaion: operation?
    private final var _hasDotInCurrentValue = false
    private final var _isCurrentValueNegative = false
    private final var _shouldInsertCurrentExpressionCell = false
    private final var _isLastOperation = false
    private final var _shouldAC = true
    private final var _lastResult = 0.0
    
    /// Used to store formulas.
    /// Stored in an array, each number and calculation symbol will be separated.
    private final var _expressions: Array<String> = [] {
        didSet {
            _updateDisplay()
        }
    }
    
    private func _updateDisplay() {
        var displayText = _expressions.joined(separator: " ")
        
        _mathOperatorDisplayDict.forEach { (displayChar, realOptr) in
            displayText = displayText.replacingOccurrences(of: realOptr, with: displayChar)
        }
        
        let currentExpressions = _insertCurrentExpressionCell(expectOperation: _isLastOperation)
        
        // Update UI for showing current formula.
        expressionLabel.text = displayText + " " + currentExpressions.joined(separator: " ")
        
        if _shouldAC {
            resetButton.setTitle("AC", for: .normal)
        } else {
            resetButton.setTitle("C", for: .normal)
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
    
    private func _modifyCurrentValue(value cell: String) {
        if cell.isNumber() {
            _shouldAC = _expressions.isEmpty
            
            if _currentValue == nil {
                
                _currentValue = cell
                return
            }
            
            if cell == "0" && _currentValue == "0" {
                return
            }
            
            if _shouldInsertCurrentExpressionCell {
                let expression = _insertCurrentExpressionCell()
                _expressions.append(contentsOf: expression)
                _currentValue = cell
                _isLastOperation = true
                _shouldAC = _expressions.isEmpty
                _isCurrentValueNegative = false
                _hasDotInCurrentValue = false
                _shouldInsertCurrentExpressionCell = false
                return
            }
            
            _currentValue! += cell
            return
        }
        
        if cell == "." {
            if _shouldInsertCurrentExpressionCell {
                let expression = _insertCurrentExpressionCell()
                _expressions.append(contentsOf: expression)
                _currentValue = "0."
                _shouldAC = _expressions.isEmpty
                _isLastOperation = true
                _isCurrentValueNegative = false
                _hasDotInCurrentValue = false
                _shouldInsertCurrentExpressionCell = false
                return
            }
            
            if _hasDotInCurrentValue {
                return
            }
            
            _shouldAC = _expressions.isEmpty
            _hasDotInCurrentValue = true
            
            if _currentValue == nil {
                _currentValue = "0."
                return
            }
            
            _currentValue! += "."
        }
        
        if cell == "%" {
            if _currentValue == nil {
                return
            }
            
            _currentValue = String(Double(_currentValue!)! * 0.01)
        }
    }
    
    private func _modifyCurrentOperation(operation: operation) {
        _currentOperaion = operation
        
        _isLastOperation = false
        _shouldInsertCurrentExpressionCell = true
        
        if _currentValue == nil {
            let lastResultWithoutPoint = Int(_lastResult)
            _currentValue = Double(lastResultWithoutPoint) == _lastResult ? String(lastResultWithoutPoint) : String(_lastResult)
        }
    }
    
    private func _toggleCurrentNegativeStatus() {
        _isCurrentValueNegative = !_isCurrentValueNegative
    }
    
    /// Zero the calculator, clear all formulas, reset the screen.
    private func _resetFormula() {
        _expressions.removeAll()
        _hasDotInCurrentValue = false
        _isCurrentValueNegative = false
        _shouldInsertCurrentExpressionCell = false
        _isLastOperation = false
        _currentValue = nil
        _currentOperaion = nil
        _lastResult = 0.0
        resultLabel.text = "0"
    }
    
    private func _c() {
        _currentValue = nil
        _isLastOperation = true
        _hasDotInCurrentValue = false
        _isCurrentValueNegative = false
        _shouldAC = true
    }
    
    private func _insertCurrentExpressionCell(expectOperation: Bool = false) -> Array<String> {
        var expressions: Array<String> = []
        
        if _currentValue == nil {
            return expressions
        }
        
        if _isCurrentValueNegative {
            expressions.append("(-" + _currentValue! + ")")
        } else {
            expressions.append(_currentValue!)
        }
        
        if !expectOperation && _currentOperaion != nil {
            expressions.append(_currentOperaion!.rawValue)
        }
        
        return expressions
    }
    
    private func _calculateFormulaResult() throws {
        let currentExpression = _insertCurrentExpressionCell(expectOperation: true)
        
        _c()
        
        _expressions.append(contentsOf: currentExpression)
        
        if (_expressions.isEmpty) {
            return
        }
        
        if (_hasDivideZero()) {
            _resetFormula()
            throw "NaN"
        }
        
        
        var formula = _expressions.joined()
        
        _mathOperatorDisplayDict.forEach { (displayChar, realOptr) in
            formula = formula.replacingOccurrences(of: displayChar, with: realOptr)
        }
        
        let realExpression = try MathExpression(formula)
        let result = realExpression.evaluate()
        
        if result.isNaN || result.isInfinite {
            _resetFormula()
            throw "NaN"
        }
        
        _lastResult = result
        
        let resultWithoutPoint = Int(result)
        
        resultLabel.text = Double(resultWithoutPoint) == result ? String(resultWithoutPoint) : String(result)
        
        _expressions.removeAll()
    }
    
    private func _hasDivideZero() -> Bool {
        for (index, cell) in _expressions.enumerated() {
            if cell == "/" && index != (_expressions.endIndex - 1) && _expressions[index + 1] == "0" {
                return true
            }
        }
        
        return false
    }
    
    /// "Touch up Inside" event handler for numeric buttons (0 ~ 9).
    @IBAction func onNumberClicked(_ sender: UIButton, forEvent event: UIEvent) {
        let clickedNumber = sender.configuration?.title
        
        // Since all possible `sender` of this function are pre-defined, which not have a nil title, so we can directly use `!` to destruct the Optinal.
        _modifyCurrentValue(value: clickedNumber!)
        _updateDisplay()
    }
    
    /// "Touch up Inside" event handler for operator buttons (+, -, ×, ÷).
    @IBAction func onOperatorClicked(_ sender: UIButton, forEvent event: UIEvent) {
        let clickedOperation = operation.init(rawValue: sender.configuration!.title!)
        _modifyCurrentOperation(operation: clickedOperation!)
        _updateDisplay()
    }
    
    /// "Touch up Inside" event handler for the reset button (AC).
    @IBAction func onResetClicked(_ sender: UIButton, forEvent event: UIEvent) {
        if _shouldAC {
            _resetFormula()
        } else {
            _c()
        }
        
        _updateDisplay()
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
        _updateDisplay()
    }
    
    
    @IBAction func onSignedClicked(_ sender: UIButton, forEvent event: UIEvent) {
        _toggleCurrentNegativeStatus()
        _updateDisplay()
    }
    
    @IBAction func onDotClicked(_ sender: UIButton, forEvent event: UIEvent) {
        _modifyCurrentValue(value: ".")
        _updateDisplay()
    }
    
    
    @IBAction func onPercentClicked(_ sender: UIButton, forEvent event: UIEvent) {
        _modifyCurrentValue(value: "%")
        _updateDisplay()
    }
}

fileprivate extension String {
    func isNumber() -> Bool {
        return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil && self.rangeOfCharacter(from: CharacterSet.letters) == nil
    }}

extension String: Error {}
