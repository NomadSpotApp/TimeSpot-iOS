//
// Date+.swift
//  Utill
//
//  Created by Wonji Suh on 7/20/24.
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

  func formattedReturnDeadlineText(addingMinutes minutes: Int) -> String {
    let deadline = Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "a h:mm"
    return formatter.string(from: deadline)
  }

  // MARK: - Departure Time Utils
  func normalizedDepartureTime(from currentTime: Date) -> Date {
    let calendar = Calendar.current
    let currentDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentTime)
    let selectedTimeComponents = calendar.dateComponents([.hour, .minute], from: self)

    guard let selectedHour = selectedTimeComponents.hour,
          let selectedMinute = selectedTimeComponents.minute else {
      return self
    }

    var normalizedComponents = DateComponents()
    normalizedComponents.year = currentDateComponents.year
    normalizedComponents.month = currentDateComponents.month
    normalizedComponents.day = currentDateComponents.day
    normalizedComponents.hour = selectedHour
    normalizedComponents.minute = selectedMinute

    guard let normalizedDate = calendar.date(from: normalizedComponents) else {
      return self
    }

    // 선택된 시간이 현재 시간보다 이전이거나 같으면 다음날로 설정
    if normalizedDate <= currentTime {
      return calendar.date(byAdding: .day, value: 1, to: normalizedDate) ?? normalizedDate
    }

    return normalizedDate
  }

  // MARK: - Route Time Utils
  /// 예상 도착 시간 계산 (현재 시간 + 소요 시간)
  /// - Parameter durationMinutes: 소요 시간 (분)
  /// - Returns: "HH:mm" 형태의 도착 예정 시간
  static func estimatedArrivalTime(durationMinutes: Int) -> String {
    let now = Date()
    let arrivalDate = now.addingTimeInterval(TimeInterval(durationMinutes * 60))

    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "HH:mm"

    return formatter.string(from: arrivalDate)
  }
}

public extension Calendar {
  func remainingTimeComponents(from currentTime: Date, to targetTime: Date) -> DateComponents {
    // targetTime이 currentTime보다 이전이면 다음날로 간주
    var adjustedTargetTime = targetTime
    if targetTime < currentTime {
      // 다음 날 같은 시간으로 조정
      adjustedTargetTime = date(byAdding: .day, value: 1, to: targetTime) ?? targetTime
    }

    let components = dateComponents([.hour, .minute], from: currentTime, to: adjustedTargetTime)
    return DateComponents(hour: max(components.hour ?? 0, 0), minute: max(components.minute ?? 0, 0))
  }
}
