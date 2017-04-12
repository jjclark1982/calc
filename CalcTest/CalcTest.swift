//
//  CalcTest.swift
//  CalcTest
//
//  Created by Jesse Clark on 13/3/17.
//  Copyright © 2017 UTS. All rights reserved.
//

import XCTest
import GameKit // for deterministic random number generator

let randomSource = GKLinearCongruentialRandomSource(seed: 2)

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
        input = "calc " + arguments.joined(separator: " ")
        
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
    func testParseInteger() {
        let n1 = randomSource.nextInt(upperBound:100)
        let task1 = calcProcess(n1)
        XCTAssertEqual(task1.output, String(n1), task1.input)
        
        let n2 = randomSource.nextInt(upperBound:100)
        let task2 = calcProcess("+\(n2)")
        XCTAssertEqual(task2.output, String(n2), task2.input)
        
        let n3 = -randomSource.nextInt(upperBound:100)
        let task3 = calcProcess(n3)
        XCTAssertEqual(task3.output, String(n3), task3.input)

        // expect out-of-bounds parsing to emit an error
        var task: calcProcess
        task = calcProcess("\(Int.max)\(randomSource.nextInt(upperBound:90)+10)")
        XCTAssertNotNil(task.status, task.input)
        task = calcProcess("-\(Int.max)\(randomSource.nextInt(upperBound:90)+10)")
        XCTAssertNotNil(task.status, task.input)
    }

    func testInvalidInput() {
        let task1 = calcProcess("x")
        XCTAssertNotNil(task1.status, "exit with nonzero status on invalid input: \(task1.input)")
        
        let task2 = calcProcess("3.1", "-4", "xyz")
        XCTAssertNotNil(task2.status, "exit with nonzero status on invalid input: \(task2.input)")

        let task3 = calcProcess("2", "+", "n")
        XCTAssertNotNil(task3.status, "exit with nonzero status on invalid input: \(task3.input)")

        let task4 = calcProcess("50%", "+", "25%")
        XCTAssertNotNil(task4.status, "exit with nonzero status on invalid input: \(task4.input)")
    }

    func testAdd() throws {
        var task: calcProcess
        let n1 = randomSource.nextInt(upperBound:100)
        let n2 = randomSource.nextInt(upperBound:100)
        let n3 = randomSource.nextInt(upperBound:100)-100
        let n4 = randomSource.nextInt(upperBound:100)-100
        
        task = calcProcess(n1, "+", n2)
        XCTAssertEqual(task.output, String(n1 + n2), task.input)

        task = calcProcess(n1, "+", n3)
        XCTAssertEqual(task.output, String(n1 + n3), task.input)
        
        task = calcProcess(n1, "+", n4)
        XCTAssertEqual(task.output, String(n1 + n4), task.input)

        task = calcProcess(n2, "+", n3)
        XCTAssertEqual(task.output, String(n2 + n3), task.input)
        
        task = calcProcess(n3, "+", n4)
        XCTAssertEqual(task.output, String(n3 + n4), task.input)

        task = calcProcess(n4, "+", n1)
        XCTAssertEqual(task.output, String(n4 + n1), task.input)

        task = calcProcess(n1, "+", n2, "+", n3, "+", n4)
        XCTAssertEqual(task.output, String(n1 + n2 + n3 + n4), task.input)
    }
    
    func testSubtract() throws {
        var task: calcProcess
        let n1 = randomSource.nextInt(upperBound:100)
        let n2 = randomSource.nextInt(upperBound:100)
        let n3 = randomSource.nextInt(upperBound:100)-100
        let n4 = randomSource.nextInt(upperBound:100)-100
        
        task = calcProcess(n1, "-", n2)
        XCTAssertEqual(task.output, String(n1 - n2), task.input)
        
        task = calcProcess(n1, "-", n3)
        XCTAssertEqual(task.output, String(n1 - n3), task.input)
        
        task = calcProcess(n1, "-", n4)
        XCTAssertEqual(task.output, String(n1 - n4), task.input)
        
        task = calcProcess(n2, "-", n3)
        XCTAssertEqual(task.output, String(n2 - n3), task.input)
        
        task = calcProcess(n3, "-", n4)
        XCTAssertEqual(task.output, String(n3 - n4), task.input)

        task = calcProcess(n4, "-", n1)
        XCTAssertEqual(task.output, String(n4 - n1), task.input)

        task = calcProcess(n1, "-", n2, "-", n3, "-", n4)
        XCTAssertEqual(task.output, String(n1 - n2 - n3 - n4), task.input)
    }
    
    func testMultiply() throws {
        var task: calcProcess
        let n1 = randomSource.nextInt(upperBound:100)+1
        let n2 = randomSource.nextInt(upperBound:100)+1
        let n3 = randomSource.nextInt(upperBound:100)-101
        
        task = calcProcess(n1, "x", n2)
        XCTAssertEqual(task.output, String(n1 * n2), task.input)

        task = calcProcess(n1, "x", n3)
        XCTAssertEqual(task.output, String(n1 * n3), task.input)

        task = calcProcess(n3, "x", n2)
        XCTAssertEqual(task.output, String(n3 * n2), task.input)

        task = calcProcess(n1, "x", n2, "x", n3)
        XCTAssertEqual(task.output, String(n1 * n2 * n3), task.input)
    }
    
    func testDivide() throws {
        var task: calcProcess
        let n1 = randomSource.nextInt(upperBound:4096) + 300
        let n2 = randomSource.nextInt(upperBound:256) + 20
        let n3 = randomSource.nextInt(upperBound:16) + 1

        task = calcProcess(n1, "/", n2)
        XCTAssertEqual(task.output, String(n1 / n2), task.input)
        
        task = calcProcess(n2, "/", n3)
        XCTAssertEqual(task.output, String(n2 / n3), task.input)
        
        task = calcProcess(n1, "/", -n3)
        XCTAssertEqual(task.output, String(n1 / -n3), task.input)
        
        task = calcProcess(n1, "/", n2, "/", n3)
        XCTAssertEqual(task.output, String(n1 / n2 / n3), task.input)
    }
    
    func testModulus() throws {
        let n1 = randomSource.nextInt(upperBound:100) + 20
        let n2 = randomSource.nextInt(upperBound:20) + 1
        let task = calcProcess(n1, "%", n2)
        XCTAssertEqual(task.output, String(n1 % n2), task.input)
    }

    func testDivideByZero() {
        let n1 = randomSource.nextInt(upperBound:100) + 1
        let task1 = calcProcess(n1, "/", 0)
        XCTAssertNotNil(task1.status, "exit with nonzero status when dividing by zero: \(task1.input)")
        
        let n2 = randomSource.nextInt(upperBound:100) + 1
        let task2 = calcProcess(n2, "%", 0)
        XCTAssertNotNil(task2.status, "exit with nonzero status when dividing by zero: \(task2.input)")
    }
    
    func testAddSubtract() throws {
        let n1 = randomSource.nextInt(upperBound:100)
        let n2 = randomSource.nextInt(upperBound:100)
        let n3 = randomSource.nextInt(upperBound:100)
        let task1 = calcProcess(n1, "+", n2, "-", n3)
        XCTAssertEqual(task1.output, String(n1 + n2 - n3), task1.input)

        let n4 = randomSource.nextInt(upperBound:200)-100
        let n5 = randomSource.nextInt(upperBound:200)-100
        let n6 = randomSource.nextInt(upperBound:200)-100
        let n7 = randomSource.nextInt(upperBound:200)-100
        let n8 = randomSource.nextInt(upperBound:200)-100
        let n9 = randomSource.nextInt(upperBound:200)-100
        let task2 = calcProcess(n4, "-", n5, "-", n6, "+", n7, "-", n8, "+", n9)
        XCTAssertEqual(task2.output, String(n4 - n5 - n6 + n7 - n8 + n9), task2.input)
    }
    
    func testMultDivide() throws {
        // verify that same-precedence is evaluated left-to-right
        let n1 = randomSource.nextInt(upperBound:50) + 5
        let n2 = randomSource.nextInt(upperBound:50) + 5
        let n3 = randomSource.nextInt(upperBound:20) + 1
        let task1 = calcProcess(n1, "x", n2, "/", n3)
        XCTAssertEqual(task1.output, String(n1 * n2 / n3), task1.input)

        // verify that same-precedence is evaluated left-to-right
        let n4 = randomSource.nextInt(upperBound:50) + 5
        let n5 = randomSource.nextInt(upperBound:50) + 5
        let n6 = randomSource.nextInt(upperBound:20) + 1
        let task2 = calcProcess(n4, "x", n5, "%", n6)
        XCTAssertEqual(task2.output, String(n4 * n5 % n6), task2.input)

        // note: these ops are not the same predence in all languages
        let n7 = randomSource.nextInt(upperBound:50) + 40
        let n8 = randomSource.nextInt(upperBound:20) + 20
        let n9 = randomSource.nextInt(upperBound:20) + 1
        let task3 = calcProcess(n7, "%", n8, "/", n9)
        XCTAssertEqual(task3.output, String((n7 % n8) / n9), task3.input)
    }

    func testPrecedence1() throws {
        // verify that multiplication is evaluated before addition
        let n1 = randomSource.nextInt(upperBound:100) + 1
        let n2 = randomSource.nextInt(upperBound:100) + 1
        let n3 = randomSource.nextInt(upperBound:100) + 1
        
        let task1 = calcProcess(n1, "x", n2, "+", n3)
        XCTAssertEqual(task1.output, String(n1 * n2 + n3), task1.input)

        let task2 = calcProcess(n1, "+", n2, "x", n3)
        XCTAssertEqual(task2.output, String(n1 + n2 * n3), task2.input)
    }

    func testPrecedence2() throws {
        // verify that division is evaluated before addition or subtraction
        let n4 = randomSource.nextInt(upperBound:100) + 1
        let n5 = randomSource.nextInt(upperBound:20) + 20
        let n6 = randomSource.nextInt(upperBound:20) + 1
        let n7 = randomSource.nextInt(upperBound:100) + 1
        let task2 = calcProcess(n4, "+", n5, "/", n6, "-", n7)
        XCTAssertEqual(task2.output, String(n4 + n5 / n6 - n7), task2.input)
    }
    
    func testOutOfBounds() {
        let support64bit = (calcProcess(Int.max).output == String(Int.max))
        var min = Int.min
        var max = Int.max
        if (!support64bit) {
            min = Int(Int32.min)
            max = Int(Int32.max)
        }
        // test additive overflow
        let n1 = max - randomSource.nextInt(upperBound:50)
        let n2 = randomSource.nextInt(upperBound:100) + 60
        let task1 = calcProcess(n1, "+", n2)
        XCTAssertNotNil(task1.status, "Error on integer overflow: \(task1.input)")
        let task2 = calcProcess(n1, "-", -n2)
        XCTAssertNotNil(task2.status, "Error on integer overflow: \(task2.input)")

        // test additive underflow
        let n3 = min + randomSource.nextInt(upperBound:50)
        let n4 = randomSource.nextInt(upperBound:100) + 60
        let task3 = calcProcess(n3, "-", n4)
        XCTAssertNotNil(task3.status, "Error on integer underflow: \(task3.input)")
        let task4 = calcProcess(n3, "+", -n4)
        XCTAssertNotNil(task4.status, "Error on integer underflow: \(task4.input)")

        // test multiplicative overflow
        let n5 = Int(Int32.max) - randomSource.nextInt(upperBound:100)
        let n6 = Int(Int32.max) - randomSource.nextInt(upperBound:100)
        let n7 = Int(Int32.max) - randomSource.nextInt(upperBound:100)
        let task5 = calcProcess(n5, "x", n6, "x", n7)
        XCTAssertNotNil(task5.status, "Error on integer overflow: \(task5.input)")

        let task6 = calcProcess(-n5, "x", n6, "x", n7)
        XCTAssertNotNil(task6.status, "Error on integer underflow: \(task6.input)")
    }
}
