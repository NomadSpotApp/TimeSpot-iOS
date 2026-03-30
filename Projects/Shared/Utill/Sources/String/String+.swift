//
//  String+.swift
//  Utill
//
//  Created by Wonji Suh  on 11/4/24.
//

import Foundation

public extension String {
  static func makeQrCodeValue(
    userID: String,
    eventID: String,
    startTime: Date,
    endTime: Date
  ) -> String {
    let startTimeString = startTime.formattedString()
    let setEndTime = endTime.addingTimeInterval(1800)
    let endTimeString = setEndTime.formattedString()
    return "\(userID)+\(eventID)+\(startTimeString)+\(endTimeString)"
  }
  
  static func stringToDate(_ dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일"
    return dateFormatter.date(from: dateString)
  }
  
  static func stringToTimeAndDate(_ dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일 a hh시 mm분"
    return dateFormatter.date(from: dateString)
  }
  
  static func stringToTimeFirebaseDate(_ dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = "yyyy년 MM월 dd일 a hh시 mm분 ss초 'UTC'Z"
    return dateFormatter.date(from: dateString)
  }
  
  static func extractMonth(from isoDate: String) -> String {
    let components = isoDate.split(separator: "T").first?.split(separator: "-")
    return components?.count == 3 ? String(components![1]) : ""
  }
  
  static func extractDay(from isoDate: String) -> String {
    let components = isoDate.split(separator: "T").first?.split(separator: "-")
    return components?.count == 3 ? String(components![2]) : ""
  }
  
  static func extractMonthString(from isoDate: String) -> String {
      let comps = isoDate.split(separator: "T").first?.split(separator: "-")
      if let month = comps?[1] {
        return "\(Int(month) ?? 0)월"
      }
      return ""
    }

  static func monthOnlyString(from input: String) -> String? {
    // "10:000" -> "10:00.000" 보정
    let fixed = input.replacingOccurrences(
      of: #"T(\d{2}):(\d{2})(\d{3})([+\-]\d{2}:\d{2})$"#,
      with: #"T$1:$2.$3$4"#,
      options: .regularExpression
    )

    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    let date: Date?
    if let d = iso.date(from: fixed) {
      date = d
    } else {
      iso.formatOptions = [.withInternetDateTime]
      date = iso.date(from: fixed)
    }
    guard let date else { return nil }

    let out = DateFormatter()
    out.locale = Locale(identifier: "ko_KR")
    out.timeZone = TimeZone(identifier: "Asia/Seoul")
    out.dateFormat = "MM월"   // ✅ 08월
    return out.string(from: date)
  }

  static func dayOnlyString(from input: String) -> String? {
    // "10:000" -> "10:00.000" 보정
    let fixed = input.replacingOccurrences(
      of: #"T(\d{2}):(\d{2})(\d{3})([+\-]\d{2}:\d{2})$"#,
      with: #"T$1:$2.$3$4"#,
      options: .regularExpression
    )

    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    let date: Date?
    if let d = iso.date(from: fixed) {
      date = d
    } else {
      iso.formatOptions = [.withInternetDateTime]
      date = iso.date(from: fixed)
    }
    guard let date else { return nil }

    let out = DateFormatter()
    out.locale = Locale(identifier: "ko_KR")
    out.timeZone = TimeZone(identifier: "Asia/Seoul")
    out.dateFormat = "d일"   // ✅ 16일
    return out.string(from: date)
  }

  static func splitBySlash(_ input: String) -> (left: String, right: String) {
    let components = input.components(separatedBy: " / ")
    let left = components.first ?? ""
    let right = components.count > 1 ? components[1] : ""
    return (left, right)
  }

  // ISO8601 문자열을 Date로 변환하는 유틸리티 메서드
  func toDate() -> Date? {
    // "10:000" -> "10:00.000" 보정
    let fixed = self.replacingOccurrences(
      of: #"T(\d{2}):(\d{2})(\d{3})([+\-]\d{2}:\d{2})$"#,
      with: #"T$1:$2.$3$4"#,
      options: .regularExpression
    )

    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    // fractionalSeconds로 시도 후 실패하면 일반 포맷으로 재시도
    return iso.date(from: fixed) ?? {
      iso.formatOptions = [.withInternetDateTime]
      return iso.date(from: fixed)
    }()
  }

  func formattedClosingTimeText() -> String {
    if let time = self.split(separator: " ").last {
      let hhmm = String(time.prefix(5))
      return "\(hhmm)에 영업종료"
    }
    return self
  }

  var stayableMinutesDisplayText: String {
    let text = self
      .replacingOccurrences(of: " 체류 가능", with: "")
      .replacingOccurrences(of: "약 ", with: "")
    let value = text.isEmpty ? "0분" : text
    return "약 \(value)"
  }

  func walkMinutesDisplayText(
    spotName: String,
    subtitle: String,
    distanceText: String
  ) -> String {
    let text = self
      .replacingOccurrences(of: "\(spotName)에서 약 ", with: "")
      .replacingOccurrences(of: "\(subtitle)에서 약 ", with: "")
      .replacingOccurrences(of: "\(distanceText) ", with: "")
      .components(separatedBy: "약 ")
      .last?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    return (text?.isEmpty == false ? text! : "0분")
  }

  var normalizedURL: URL? {
    let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    if let url = URL(string: trimmed) {
      return url
    }

    let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    return encoded.flatMap(URL.init(string:))
  }

  var minutesValue: Int {
    Int(
      replacingOccurrences(of: "약 ", with: "")
        .replacingOccurrences(of: "분", with: "")
    ) ?? 0
  }

  static func openingHoursText(status: String?, closing: String?) -> String {
    switch (status?.nilIfEmpty, closing?.nilIfEmpty) {
    case let (status?, closing?):
      return "\(status)  \(closing)"
    case let (status?, nil):
      return status
    case let (nil, closing?):
      return closing
    case (nil, nil):
      return "영업 시간 정보 준비 중"
    }
  }

  var formattedPlaceNameForDisplay: String {
    var value = self

    let patterns = [
      #"(?<=[가-힣A-Za-z0-9])(서울역|용산역|청량리역|강릉역|수서역|부산역|대전역|동대구역)"#,
      #"(?<=(서울역|용산역|청량리역|강릉역|수서역|부산역|대전역|동대구역))(?=[가-힣A-Za-z0-9])"#,
      #"(?<=[가-힣A-Za-z0-9])(롯데아울렛|현대아울렛|신세계아울렛)"#
    ]

    for pattern in patterns {
      value = value.replacingOccurrences(
        of: pattern,
        with: pattern.contains("(?=") ? " " : " $1",
        options: .regularExpression
      )
    }

    value = value.replacingOccurrences(
      of: #"\s+"#,
      with: " ",
      options: .regularExpression
    )

    return value.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var nilIfEmpty: String? {
    isEmpty ? nil : self
  }

  // MARK: - Station Utils
  var normalizedStationName: String {
    self
      .replacingOccurrences(of: "역", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
