//
// Date+.swift
//  Utill
//
//  Created by 서원지 on 7/20/24.
//

import Foundation


public extension Date {
  func formattedString() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.string(from: self)
  }
  
  func formattedDate(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일"
    return dateFormatter.string(from: date)
  }
  
  
  func formattedTime(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "a hh시 mm분"
    return dateFormatter.string(from: date)
  }
  
  func formattedTimes(date: Date) -> String {
    let dateFormatter = DateFormatter()
    //        dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "h:mm a"
    return dateFormatter.string(from: date)
  }
  
  func formattedDateToString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일"
    return dateFormatter.string(from: self)
  }
  
  func formattedDates() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: self)
  }
  
  func formattedDateTimeToString(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일 a hh시 mm분"
    dateFormatter.dateStyle = .short
    return dateFormatter.string(from: date)
  }
  
  func formattedDateTimeText(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy.MM.dd"
    return dateFormatter.string(from: date)
  }
  
  func extractDate(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "MM월"
    return dateFormatter.string(from: date)
  }
  
  func formattedFireBaseDate(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일 a hh시 mm분 ss초 'UTC'Z"
    return dateFormatter.string(from: date)
  }
  
  func formattedFireBaseStringToDate(dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일 a h시 mm분 ss초 'UTC'Z"
    return dateFormatter.date(from: dateString) ?? Date()
  }
  
  func dateFromTimeToString(dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
    return dateFormatter.date(from: dateString) ?? Date()
  }
  
  func dateFromString(dateString: String) -> Date {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일 EEEE"
    return dateFormatter.date(from: dateString) ?? Date()
  }
  
  
  func toFormattedString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy년 MM월"
    return dateFormatter.string(from: self)
  }

  /// 한국어 날짜 + 요일 포맷 (예: 2026년 3월 17일 화요일)
  func formattedKoreanDateWithWeekday() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 M월 d일 EEEE"
    return dateFormatter.string(from: self)
  }

  /// 특정 날짜를 한국어 날짜 + 요일 포맷으로 변환 (예: 2026년 3월 17일 화요일)
  static func formattedKoreanDateWithWeekday(from date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 M월 d일 EEEE"
    return dateFormatter.string(from: date)
  }

  /// 한국어 시간 포맷 (예: 오후 3시 32분)
  func formattedKoreanTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "a h시 m분"
    return dateFormatter.string(from: self)
  }

  /// 특정 시간을 한국어 시간 포맷으로 변환 (예: 오후 3시 32분)
  static func formattedKoreanTime(from date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "a h시 m분"
    return dateFormatter.string(from: date)
  }
}

public extension Calendar {
  func remainingTimeComponents(from currentTime: Date, to targetTime: Date) -> DateComponents {
    let components = dateComponents([.hour, .minute], from: currentTime, to: targetTime)
    return DateComponents(hour: max(components.hour ?? 0, 0), minute: max(components.minute ?? 0, 0))
  }
}
