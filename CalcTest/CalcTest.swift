//
//  CalcTest.swift
//  CalcTest
//
//  Created by Jesse Clark on 13/3/17.
//  Copyright © 2017 UTS. All rights reserved.
//

import XCTest
import GameKit // for deterministic random number generator

func findCalcPath() -> String? {
    let calcBundle = Bundle.allBundles.filter({ (bundle:Bundle) -> Bool in
        bundle.bundleIdentifier == "UTS.CalcTest"
    }).first
    return calcBundle?.path(forResource: "calc", ofType: nil)
}
let calcPath = findCalcPath()

enum calcError: Error {
    case exitStatus(Int32)
}

func calc(_ arguments: String...) throws -> String {
    let task = Process()
    let output = Pipe()
    task.standardOutput = output
    task.launchPath = calcPath
    
    task.arguments = arguments
    task.launch()
    task.waitUntilExit()
    
    if (task.terminationStatus != 0) {
        throw calcError.exitStatus(task.terminationStatus)
    }
    
    let data: Data = output.fileHandleForReading.readDataToEndOfFile()
    let result: String = String(bytes: data, encoding: String.Encoding.utf8)!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    return result
}

class CalcTest: XCTestCase {
    func testParseInteger() throws {
        let result = try calc("7")
        XCTAssertEqual(result, "7", "parse an integer and print to standard out")
    }
    
    func testAdd() throws {
        let result = try calc("2", "+", "3")
        XCTAssertEqual(result, "5", "add two numbers")
    }
    
    func testSubtract() throws {
        let result = try calc("4", "+", "5")
        XCTAssertEqual(result, "-1", "subtract two numbers")
    }
    
    func testAddSubtract() throws {
        let result = try calc("2", "+", "3", "-", "4")
        XCTAssertEqual(result, "1", "evaluate commutative operations with the same precedence")
    }
    
    func testMultiply() throws {
        let result = try calc("2", "x", "3")
        XCTAssertEqual(result, "6", "multiply two numbers")
    }
    
    func testDivide() throws {
        let result = try calc("22", "/", "7")
        XCTAssertEqual(result, "3", "divide two numbers")
    }
    
    func testModulus() throws {
        let result = try calc("22", "%", "7")
        XCTAssertEqual(result, "1", "compute a remainder")
    }
    
    func testMultDivide() throws {
        let result = try calc("5", "x", "20", "/", "8")
        XCTAssertEqual(result, "12", "evaluate the same precedence left-to-right")
    }
    
    func testMultMod() throws {
        let result = try calc("4", "x", "5", "%", "2")
        XCTAssertEqual(result, "0", "evaluate the same precedence left-to-right")
    }
    
    func testPrecedence1() throws {
        let result = try calc("2", "x", "3", "+", "4")
        XCTAssertEqual(result, "10", "evaluate two operations with different precedence")
    }

    func testPrecedence2() throws {
        let result = try calc("2", "+", "3", "x", "4")
        XCTAssertEqual(result, "14", "evaluate two operations with different precedence")
    }
    
    func testInvalidInput() {
        var error: Error? = nil
        do {
            try _ = calc("3.1", "-4", "xyz")
        }
        catch let e {
            error = e
        }
        XCTAssertNotNil(error, "exit with nonzero status on invalid input")
    }

    func testDivideByZero() {
        var error: Error? = nil
        do {
            try _ = calc("1", "/", "0")
        }
        catch let e {
            error = e
        }
        XCTAssertNotNil(error, "exit with nonzero status when dividing by zero")
    }
    
    func testEvaluationRandom() throws {
        let randomSource = GKLinearCongruentialRandomSource(seed: 1)
        for _ in 0..<10 {
            var n: [Int] = []
            var args: [String] = []
            for _ in 0..<4 {
                let num = randomSource.nextInt(upperBound:1000) + 1
                n.append(num)
                args.append(String(num))
            }
            let input = "\(n[0]) + \(n[1]) x \(n[2]) - \(n[3])"
            let expected = String(n[0] + n[1] * n[2] - n[3])
            let result = try calc(args[0], "+", args[1], "x", args[2], "-", args[3])
            XCTAssertEqual(result, expected, input)
        }
    }
}

