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

  /// 10자 이상인 텍스트에 중간 스페이스 추가
  var formatLongText: String {
    guard self.count > 10 else { return self }

    let characters = Array(self)
    let midPoint = characters.count / 2

    // 중간점 근처에서 적절한 위치 찾기 (±2 범위 내)
    let searchRange = max(0, midPoint - 2)...min(characters.count - 1, midPoint + 2)

    // 이미 스페이스가 있는 위치 찾기
    if searchRange.first(where: { characters[$0] == " " }) != nil {
      return self
    }

    // 스페이스가 없으면 중간에 스페이스 추가
    let insertIndex = midPoint
    var result = characters
    result.insert(" ", at: insertIndex)

    return String(result)
  }

  // MARK: - Station Utils
  var normalizedStationName: String {
    self
      .replacingOccurrences(of: "역", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

// MARK: - Distance Formatting
public extension Int {
  /// 미터 단위 거리를 적절한 단위로 포맷팅
  /// 1000m 이상은 km로, 그 이하는 m로 표시
  var formattedDistance: String {
    if self >= 1000 {
      let kilometers = Double(self) / 1000.0

      // 1.0km, 2.5km 등으로 표시 (소수점 1자리까지, 불필요한 .0은 제거)
      if kilometers == Double(Int(kilometers)) {
        return "\(Int(kilometers))km"
      } else {
        return String(format: "%.1fkm", kilometers)
      }
    } else {
      return "\(self)m"
    }
  }

  /// 분 단위 시간을 포맷팅
  /// 60분 이상은 시간으로, 그 이하는 분으로 표시
  var formattedDuration: String {
    if self >= 60 {
      let hours = self / 60
      let minutes = self % 60

      if minutes == 0 {
        return "\(hours)시간"
      } else {
        return "\(hours)시간 \(minutes)분"
      }
    } else {
      return "\(self)분"
    }
  }
}
