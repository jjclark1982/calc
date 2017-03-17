//
//  CalcTest.swift
//  CalcTest
//
//  Created by Jesse Clark on 13/3/17.
//  Copyright © 2017 UTS. All rights reserved.
//

import XCTest
import GameKit // for deterministic random number generator

let randomSource = GKLinearCongruentialRandomSource(seed: 1)

let calcBundle = Bundle(identifier: "UTS.CalcTest")!
let calcPath = calcBundle.path(forResource: "calc", ofType: nil)

enum calcError: Error {
    case exitStatus(Int32)
}

class calcProcess {
    var input: String
    var output: String
    var status: calcError?
    
    init(_ args:Any...) {
        let arguments = args.map { (a:Any) -> String in
            String(describing:a)
        }
        input = arguments.joined(separator: " ")
        
        let task = Process()
        let stdout = Pipe()
        task.standardOutput = stdout
        task.launchPath = calcPath
        task.arguments = arguments
        task.launch()
        task.waitUntilExit()
        
        if (task.terminationStatus != 0) {
            status = calcError.exitStatus(task.terminationStatus)
        }

        let data: Data = stdout.fileHandleForReading.readDataToEndOfFile()
        output = String(bytes: data, encoding: String.Encoding.utf8)!.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

class CalcTest: XCTestCase {
    func testParseInteger() throws {
        let n1 = randomSource.nextInt(upperBound:100)
        let task = calcProcess(n1)
        XCTAssertEqual(task.output, String(n1), task.input)

        let n2 = -randomSource.nextInt(upperBound:100)
        let task2 = calcProcess(n2)
        XCTAssertEqual(task2.output, String(n2), task.input)
    }

    func testInvalidInput() {
        let task1 = calcProcess("x")
        XCTAssertNotNil(task1.status, "exit with nonzero status on invalid input: \(task1.input)")
        
        let task2 = calcProcess("3.1", "-4", "xyz")
        XCTAssertNotNil(task2.status, "exit with nonzero status on invalid input: \(task2.input)")
    }

    func testAdd() throws {
        let n1 = randomSource.nextInt(upperBound:200)-100
        let n2 = randomSource.nextInt(upperBound:200)-100
        let task = calcProcess(n1, "+", n2)
        XCTAssertEqual(task.output, String(n1 + n2), task.input)
    }
    
    func testSubtract() throws {
        let n1 = randomSource.nextInt(upperBound:100)
        let n2 = randomSource.nextInt(upperBound:100)
        let task = calcProcess(n1, "-", n2)
        XCTAssertEqual(task.output, String(n1 - n2), task.input)
    }
    
    func testAddSubtract() throws {
        let n1 = randomSource.nextInt(upperBound:100)
        let n2 = randomSource.nextInt(upperBound:100)
        let n3 = randomSource.nextInt(upperBound:100)
        let task = calcProcess(n1, "+", n2, "-", n3)
        XCTAssertEqual(task.output, String(n1 + n2 - n3), task.input)
    }
    
    func testMultiply() throws {
        let n1 = randomSource.nextInt(upperBound:100)+1
        let n2 = randomSource.nextInt(upperBound:100)+1
        let task = calcProcess(n1, "x", n2)
        XCTAssertEqual(task.output, String(n1 * n2), task.input)
    }
    
    func testDivide() throws {
        let n1 = randomSource.nextInt(upperBound:100) + 20
        let n2 = randomSource.nextInt(upperBound:20) + 1
        let task = calcProcess(n1, "/", n2)
        XCTAssertEqual(task.output, String(n1 / n2), task.input)
    }
    
    func testModulus() throws {
        let n1 = randomSource.nextInt(upperBound:100) + 20
        let n2 = randomSource.nextInt(upperBound:20) + 1
        let task = calcProcess(n1, "%", n2)
        XCTAssertEqual(task.output, String(n1 % n2), task.input)
    }

    func testMultDivide() throws {
        // verify that same-precedence is evaluated left-to-right
        let n1 = randomSource.nextInt(upperBound:50) + 5
        let n2 = randomSource.nextInt(upperBound:50) + 5
        let n3 = randomSource.nextInt(upperBound:20) + 1
        let task = calcProcess(n1, "x", n2, "/", n3)
        XCTAssertEqual(task.output, String(n1 * n2 / n3), task.input)
    }

    func testMultMod() throws {
        // verify that same-precedence is evaluated left-to-right
        let n1 = randomSource.nextInt(upperBound:50) + 5
        let n2 = randomSource.nextInt(upperBound:50) + 5
        let n3 = randomSource.nextInt(upperBound:20) + 1
        let task = calcProcess(n1, "x", n2, "%", n3)
        XCTAssertEqual(task.output, String(n1 * n2 % n3), task.input)
    }
    
    func testModDiv() throws {
        // verify that same-precedence is evaluated left-to-right
        // note: these ops are not the same predence in all languages
        let n1 = randomSource.nextInt(upperBound:50) + 40
        let n2 = randomSource.nextInt(upperBound:20) + 20
        let n3 = randomSource.nextInt(upperBound:20) + 1
        let task = calcProcess(n1, "%", n2, "/", n3)
        XCTAssertEqual(task.output, String((n1 % n2) / n3), task.input)
    }

    func testPrecedence1() throws {
        // verify that multiplication is evaluated before addition
        let n1 = randomSource.nextInt(upperBound:20) + 1
        let n2 = randomSource.nextInt(upperBound:20) + 1
        let n3 = randomSource.nextInt(upperBound:100) + 1
        let task = calcProcess(n1, "x", n2, "+", n3)
        XCTAssertEqual(task.output, String(n1 * n2 + n3), task.input)
    }

    func testPrecedence2() throws {
        // verify that multiplication is evaluated before addition
        let n1 = randomSource.nextInt(upperBound:100) + 1
        let n2 = randomSource.nextInt(upperBound:20) + 1
        let n3 = randomSource.nextInt(upperBound:20) + 1
        let task = calcProcess(n1, "+", n2, "x", n3)
        XCTAssertEqual(task.output, String(n1 + n2 * n3), task.input)
    }
    
    func testDivideByZero() {
        let n1 = randomSource.nextInt(upperBound:100) + 1
        let task1 = calcProcess(n1, "/", 0)
        XCTAssertNotNil(task1.status, "exit with nonzero status when dividing by zero: \(task1.input)")
        
        let n2 = randomSource.nextInt(upperBound:100) + 1
        let task2 = calcProcess(n2, "%", 0)
        XCTAssertNotNil(task2.status, "exit with nonzero status when dividing by zero: \(task2.input)")
    }
}

class OptionalTests: XCTestCase {
    func testHandleFloatingPointValues() throws {
        let task = calcProcess("0.5", "+", "0.5")
        XCTAssertEqual(task.output, "1.0", "handle floating-point values: \(task.input)")
    }

    func testHandleDecimalValues() throws {
        let task = calcProcess("0.1", "+", "0.2")
        XCTAssertEqual(task.output, "0.3", "handle decimal values: \(task.input)")
    }

    func testHandleRationalValues() throws {
        let task = calcProcess("1", "/", "3", "+", "2", "/", "3")
        XCTAssertEqual(task.output, "1", "handle rational values: \(task.input)")
    }
}
