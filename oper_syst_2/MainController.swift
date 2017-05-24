//
//  MainController.swift
//  oper_syst_2
//
//  Created by Aleksandr Kozhevnikov on 26/02/2017.
//  Copyright © 2017 Aleksandr Kozhevnikov. All rights reserved.
//

import Foundation
import Cocoa

let formatter = DateFormatter()
var vc: ViewController?

struct LogItem{
    let time: String
    let operation: String
}
struct ProcessItem{
    let pid: String
    let task: String
    let priority: Int
}
var logItems = [LogItem]()
var quiueItems = [ProcessItem]()

func toLog(text: String){
    logItems.append(LogItem(time: "\(formatter.string(from: Date()))", operation: text))
    let height = vc!.logTable.frame.height
    vc!.logTable.reloadData()
    vc!.logScrollView.contentView.scroll(NSPoint(x: 0, y: height))
}

enum ProcessStatus{
    case idle //    - бездействие;
    case ready //    - готовность;
    case runned //    - выполнение;
    case waiting //    - ожидание окончания вывода.
}

enum TaskError : Error {
    case RuntimeError(String)
}

let mainQuiue = DispatchQueue.main
let userQuiue = DispatchQueue.global(qos: .userInitiated)
let backgroundQuiue = DispatchQueue.global(qos: .default)
let serialQuiue = DispatchQueue(label: "oper_syst_1.serialQuiue")
let isolationQueue = DispatchQueue(label: "oper_syst_1.isolationQueue", qos: .userInitiated, attributes: .concurrent)

var M1: Int = Int(0)
var M2 = [Int]()
var f1Result = 0
var f2Result = 0
var f3Result = 0
var f4Result = 0
var f5Result = 0
var f6Result = 0
var f7Result = 0
var f8Result = 0
var f9Result = 0

//генерирует массив и число
func f0(){
    sleep(arc4random_uniform(3) + 1)
    M1 = Int(arc4random_uniform(100)) + 1 //генерирует число от 1 до 100
    for _ in 1...M1{
        M2.append(Int(arc4random_uniform(100)) + 1)
    }
    mainQuiue.async {
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "M1: \(M1)\n--\n"))
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "M2: \(M2.description)\n--\n"))
    }
}

//вычисляет M2 + M1
func f1(){
    sleep(arc4random_uniform(3) + 1)
    for i in M2{
        f1Result += i
    }
    f1Result += M1
    mainQuiue.async {
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "Результат f1: \(f1Result)\n--\n"))
    }
}

//вычисляет M2 - M1
func f2(){
    sleep(arc4random_uniform(3) + 1)
    for i in M2{
        f2Result += i
    }
    f2Result -= M1
    mainQuiue.async {
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "Результат f2: \(f2Result)\n--\n"))
    }
}

//f1 - 3
func f3(){
    sleep(arc4random_uniform(3) + 1)
    f3Result = f1Result - 3
    mainQuiue.async {
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "Результат f3: \(f3Result)\n--\n"))
    }
}

//f1 - 4
func f4(){
    sleep(arc4random_uniform(3) + 1)
    f4Result = f1Result - 4
    mainQuiue.async {
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "Результат f4: \(f4Result)\n--\n"))
    }
}

//f1 - 5
func f5(){
    sleep(arc4random_uniform(3) + 1)
    f5Result = f1Result - 5
    mainQuiue.async {
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "Результат f5: \(f5Result)\n--\n"))
    }
}

//f2 + f4 + f5
func f6(){
    sleep(arc4random_uniform(3) + 1)
    f6Result = f4Result + f4Result + f5Result
    mainQuiue.async {
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "Результат f6: \(f6Result)\n--\n"))
    }
}

//f2 - f4 - f5
func f7(){
    sleep(arc4random_uniform(3) + 1)
    f7Result = f4Result - f4Result - f5Result
    mainQuiue.async {
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "Результат f7: \(f7Result)\n--\n"))
    }
}

//f3 + f6 + f7
func f8(){
    sleep(arc4random_uniform(3) + 1)
    f8Result = f3Result + f6Result + f7Result
    mainQuiue.async {
        vc?.logWindow.textStorage?.append(NSAttributedString(string: "Результат f8: \(f8Result)\n--\n"))
    }
}

class Process
{
    let id: String //идентификатор процесса
    var addedTimestamp: Double? //время добавления в ТМ
    var executingTimestamp: Double? //время изменения статуса
    var dependencies = [String]()  //зависимости
    var holder = [String]() //от него зависят
    private var _quiueTime: Double? { //время проведенное в очереди
        didSet{
            guard _status == .ready else{
                return
            }
            self.priority = Int(Double(self.pr0i!) + Double(self.ai!) * (self._quiueTime! - self.addedTimestamp!)) //перерасчет приоритета
        }
    }
    private var quiueTime: Double? {
        get{
            var quiueTime: Double!
            isolationQueue.sync {
                quiueTime =  self._quiueTime
            }
            return quiueTime
        }
        set (time){
            isolationQueue.async(flags: .barrier) {
                self._quiueTime = time
            }
        }
        
    }
    private let pr0i: Int? //начальный приоритет
    private let ai: Int? //коэффициент множителя
    var task: (() -> ())? //указатель на задачу
    var description: String //описание
    private var _status = ProcessStatus.idle {
        didSet {
            let newTimestamp = Date.timeIntervalSinceReferenceDate
            if oldValue != _status {
                if (executingTimestamp != nil){
                    let t = newTimestamp - executingTimestamp!
                    mainQuiue.async {
                        toLog(text: "ℹ️ Процесс \(self.id) перешел из состояния \(oldValue) в состояние \(self._status) за \(Double(round(1000*t)/1000)) сек")
                    }
                }else{
                    mainQuiue.async {
                        toLog(text: "ℹ️ Процесс \(self.id) перешел из состояния \(oldValue) в состояние \(self._status)")
                    }
                }
            }
            executingTimestamp = newTimestamp
        }
    }
    var status: ProcessStatus {
        get{
            var status: ProcessStatus!
            isolationQueue.sync {
                status =  self._status
            }
            return status
        }
        set (status){
            isolationQueue.async(flags: .barrier) {
                self._status = status
            }
        }
    }
    static var maxPriorityLevelForAllProcesses = 1 //максимальный приоритет для всех экземпляров Process
    static var maxAllowedPriorityLevel = 100 { //максимально допустимый приоритет
        didSet {
            if oldValue != maxAllowedPriorityLevel {
                toLog(text: "Изменен максимально допустимый приоритет: \(oldValue) => \(maxAllowedPriorityLevel)")
            }
        }
    }
    var priority: Int = 1 {
        didSet {
            priority = priority > Process.maxAllowedPriorityLevel ? Process.maxAllowedPriorityLevel : priority
            if priority > Process.maxPriorityLevelForAllProcesses {
                // обновляем максимальный приоритет всех процессов после установки приоритета
                Process.maxPriorityLevelForAllProcesses = priority
            }
        }
    }
    func runTask() throws -> Void {
        if self.task != nil{
            self.task!()
        } else{
            throw TaskError.RuntimeError("Ошибка запуска задачи в процессе \(self.id)")
        }
    }
    func updateQuiueTime(){
        self.quiueTime = Date.timeIntervalSinceReferenceDate
    }
    init(id: String, pr0i: Int, ai: Int, withTask task: (() -> ())?, andDescription description: String, withDependencies dependencies: [String]? = nil) {
        self.id = id
        self.pr0i = (pr0i >= 1 ? pr0i : 1)
        self.ai = (ai >= 1 ? ai : 1)
        self.task = task
        self.description = description
        if dependencies != nil {
            self.dependencies = dependencies!
        }
        
    }
}

class TaskManager
{
    static let sharedInstance = TaskManager() // синглтон
    private init(){} //закрываем инициализатор
    
    var _isRunning = false
    var isRunning: Bool {
        get{
            var isRunning: Bool!
            isolationQueue.sync {
                isRunning =  self._isRunning
            }
            return isRunning
        }
        set (val){
            isolationQueue.sync(flags: .barrier) {
                self._isRunning = val
            }
        }
    }
    private var _nowRunning = 0
    private var nowRunning: Int { //счетчик запущенных процессов
        get{
            var nowRunning: Int!
            isolationQueue.sync {
                nowRunning =  self._nowRunning
            }
            return nowRunning
        }
        set (val){
            isolationQueue.sync(flags: .barrier) {
                self._nowRunning = val
            }
        }
    }
    var interval = 1 //интервал перерасчета приоритетов
    private var _processQuiue = [String: Process]() //главная очередь
    var processQuiue: [String: Process]? {
        get{
            var processQuiue: [String: Process]!
            isolationQueue.sync {
                processQuiue =  self._processQuiue
            }
            return processQuiue
        }
        set (process){
            isolationQueue.async(flags: .barrier) {
                self._processQuiue = process!
            }
        }
    }
    private var _completed = [String: Process]() //массив завершенных процессов
    var completed: [String: Process]?{
        get{
            var completed: [String: Process]!
            isolationQueue.sync {
                completed =  self._completed
            }
            return completed
        }
        set (process){
            isolationQueue.async(flags: .barrier) {
                self._completed = process!
            }
        }
    }
    private var _runned = [String: Process]()
    var runned: [String: Process]? {
        get{
            var runned: [String: Process]!
            isolationQueue.sync {
                runned =  self._runned
            }
            return runned
        }
        set (process){
            isolationQueue.async(flags: .barrier) {
                self._runned = process!
            }
        }
    }
    var supportParallelTask = 0 { //количество параллельных процессов
        didSet {
            if oldValue != supportParallelTask {
                toLog(text: "Изменено значение поддерживаемых процессов: \(oldValue) => \(supportParallelTask)")
            }
        }
    }
    
    static func create(withsupportTask supportTask: Int, andMaxAllowedPriorityLevel maxAllowedPriorityLevel: Int) -> TaskManager {
        let tm = TaskManager.sharedInstance
        tm.supportParallelTask = supportTask
        Process.maxAllowedPriorityLevel = maxAllowedPriorityLevel
        toLog(text: "TaskManager создан.")
        return tm
    }
    
    func addProcess(process: Process) -> Void {
        process.addedTimestamp = Date.timeIntervalSinceReferenceDate
        self.processQuiue![process.id] = process
        mainQuiue.async {
            toLog(text: "❗️Процесс \(process.id) добавлен в очередь")
            vc!.quiueTableView.reloadData()
        }
        if process.dependencies.count == 0 {
            process.status = .ready
        }
        
    }
    
    func startProccess(pid: String) -> Void {
        userQuiue.async{
            if let proc = self.processQuiue?[pid]{
                do {
                    mainQuiue.async {
                        self.runned?[proc.id] = proc //перемещаем в запущенные
                        vc!.runnedTableView.reloadData()
                        self.processQuiue!.removeValue(forKey: pid)
                        vc!.quiueTableView.reloadData()
                        toLog(text: "🔆 Процесс \(proc.id) стартует с приоритетом \(proc.priority)")
                    }
                    proc.status = .runned
                    try proc.runTask()
                    proc.status = .waiting
                    mainQuiue.async {
                        vc!.quiueTableView.reloadData()
                        let t = proc.executingTimestamp! - proc.addedTimestamp!
                        toLog(text: "✅ Процесс \(proc.id) выполнен. Общее время выполнения: \(Double(round(1000*t)/1000)) сек")
                        for (hProcess) in proc.holder{
                            if let index = self.processQuiue?[hProcess]?.dependencies.index(of: proc.id) {
                                self.processQuiue?[hProcess]?.dependencies.remove(at: index)
                                if self.processQuiue?[hProcess]?.dependencies.count == 0 {
                                    self.processQuiue?[hProcess]?.status = .ready
                                }
                            }
                            
                        }
                        self.nowRunning -= 1
                        self.completed?[proc.id] = proc //перемещаем в завершенные
                        toLog(text: "💤 Процесс \(proc.id) перемещен в завершенные")
                        self.runned!.removeValue(forKey: pid)
                        vc!.runnedTableView.reloadData()
                    }
                } catch let err{
                    toLog(text: String(describing: err))
                }
            }
        }
    }
    
    func start(withInterval interval: Int = 1){
        self.isRunning = true
        self.interval = interval
        //выставляем зависимости
        for (pid, process) in processQuiue!{
            for (pName) in process.dependencies{
                if let dProcess = processQuiue![pName]{
                    dProcess.holder.append(pid)
                }
            }
        }
        while isRunning {
            sleep(UInt32(interval))
            //пересчитываем все приоритеты
            for (_, process) in self.processQuiue!{
                if process.status == .ready{ //только для тех, кто в очереди
                    process.updateQuiueTime() //триггер
                }
            }
            mainQuiue.async {
                vc!.quiueTableView.reloadData()
            }
            
            for (pid, process) in processQuiue!{
                if process.status == .ready && process.dependencies.count == 0{ //только для тех, кто в очереди
                    if self.nowRunning < self.supportParallelTask {
                        if process.priority >= Process.maxPriorityLevelForAllProcesses {
                            self.startProccess(pid: pid)
                            Process.maxPriorityLevelForAllProcesses = 1
                            self.nowRunning += 1
                            break
                        }
                    }
                }
            }
        }
    }
}



func startTM(sender: NSViewController){
    vc = sender as? ViewController
    formatter.dateFormat = "hh:mm:ss"
    
    let tm = TaskManager.create(withsupportTask: 1, andMaxAllowedPriorityLevel: 40)
    
    tm.supportParallelTask = 5
    Process.maxAllowedPriorityLevel = 100
    
    tm.addProcess(process: Process(id: "A", pr0i: 0, ai: 1, withTask: f0, andDescription: "процесс A"))
    tm.addProcess(process: Process(id: "B", pr0i: 1, ai: 1, withTask: f1, andDescription: "процесс B", withDependencies: ["A"]))
    tm.addProcess(process: Process(id: "C", pr0i: 2, ai: 1, withTask: f2, andDescription: "процесс C", withDependencies: ["A"]))
    tm.addProcess(process: Process(id: "D", pr0i: 3, ai: 1, withTask: f3, andDescription: "процесс D", withDependencies: ["B"]))
    tm.addProcess(process: Process(id: "E", pr0i: 2, ai: 1, withTask: f4, andDescription: "процесс E", withDependencies: ["B"]))
    tm.addProcess(process: Process(id: "F", pr0i: 2, ai: 1, withTask: f5, andDescription: "процесс F", withDependencies: ["B"]))
    tm.addProcess(process: Process(id: "G", pr0i: 3, ai: 1, withTask: f6, andDescription: "процесс G", withDependencies: ["E", "F", "C"]))
    tm.addProcess(process: Process(id: "H", pr0i: 3, ai: 1, withTask: f7, andDescription: "процесс H", withDependencies: ["E", "F", "C"]))
    tm.addProcess(process: Process(id: "K", pr0i: 4, ai: 1, withTask: f8, andDescription: "процесс K", withDependencies: ["D", "G", "H"]))
    
    backgroundQuiue.async {
        tm.start(withInterval: 1)
    }
    
}

func stopTM() {
    (TaskManager.sharedInstance).isRunning = false
}
