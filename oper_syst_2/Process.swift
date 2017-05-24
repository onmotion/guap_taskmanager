//
//  Process.swift
//  oper_syst_2
//
//  Created by Aleksandr Kozhevnikov on 26/02/2017.
//  Copyright © 2017 Aleksandr Kozhevnikov. All rights reserved.
//

import Foundation

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
let serialQuiue = DispatchQueue(label: "oper_syst_1.serialQuiue1")


func task1(){
    for _ in 1...10{
        sleep(1)
        //  print(".", terminator: "")
    }
}

func task2(){
    for _ in 1...10{
        sleep(2)
    }
}


class Process {
    let id: String //идентификатор процесса
    var addedTimestamp: Double? //время добавления в ТМ
    var executingTimestamp: Double? //время изменения статуса
    private var quiueTime: Double? { //время проведенное в очереди
        didSet{
            guard status == .ready else{
                return
            }
            self.priority = Int(Double(self.pr0i!) + Double(self.ai!) * (self.quiueTime! - self.addedTimestamp!)) //перерасчет приоритета
        }
    }
    private let pr0i: Int? //начальный приоритет
    private let ai: Int? //коэффициент множителя
    var task: (() -> ())? //указатель на задачу
    var status = ProcessStatus.idle {
        didSet {
            let newTimestamp = Date.timeIntervalSinceReferenceDate
            if oldValue != status {
                if (executingTimestamp != nil){
                    let t = newTimestamp - executingTimestamp!
                    mainQuiue.async {
                        print("\(formatter.string(from: Date())) | ℹ️ Процесс \(self.id) перешел из состояния \(oldValue) в состояние \(self.status) за \(Double(round(1000*t)/1000)) сек")
                    }
                }else{
                    mainQuiue.async {
                        print("\(formatter.string(from: Date())) | ℹ️ Процесс \(self.id) перешел из состояния \(oldValue) в состояние \(self.status)")
                    }
                }
            }
            executingTimestamp = newTimestamp
        }
    }
    static var maxPriorityLevelForAllProcesses = 1 //максимальный приоритет для всех экземпляров Process
    static var maxAllowedPriorityLevel = 100 { //максимально допустимый приоритет
        didSet {
            if oldValue != maxAllowedPriorityLevel {
                print("\(formatter.string(from: Date())) | Изменен максимально допустимый приоритет: \(oldValue) => \(maxAllowedPriorityLevel)")
            }
        }
    }
    var priority: Int = 1 {
        didSet {
            priority = priority > Process.maxAllowedPriorityLevel ? Process.maxAllowedPriorityLevel : priority
            //  print("\(formatter.string(from: Date())) | Изменен приоритет процесса \(self.id): \(oldValue) => \(priority)")
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
    init(id: String, pr0i: Int, ai: Int, withTask task: (() -> ())?) {
        self.id = id
        self.pr0i = (pr0i >= 1 ? pr0i : 1)
        self.ai = (ai >= 1 ? ai : 1)
        self.task = task
    }

}
