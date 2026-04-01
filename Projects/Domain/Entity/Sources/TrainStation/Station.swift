//
//  Station.swift
//  Entity
//
//  Created by Wonji Suh  on 3/26/26.
//

import Foundation

public enum Station: String, CaseIterable, Equatable, Hashable, Identifiable, Sendable {
  case seoul
  case yongsan
  case gwangmyeong
  case cheonanAsan
  case osong
  case gimcheonGumi
  case gyeongju
  case ulsan
  case busan
  case pohang
  case seodaejeon
  case iksan
  case jeongeup
  case gwangjuSongjeong
  case naju
  case mokpo
  case jeonju
  case namwon
  case suncheon
  case yeosuExpo
  case dongdaegu
  case daejeon
  case gangneung
  case cheongnyangri
  case manjong
  case pyeongchang

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .seoul:
      return "서울"
    case .yongsan:
      return "용산"
    case .gwangmyeong:
      return "광명"
    case .cheonanAsan:
      return "천안아산"
    case .osong:
      return "오송"
    case .gimcheonGumi:
      return "김천(구미)"
    case .gyeongju:
      return "경주"
    case .ulsan:
      return "울산"
    case .busan:
      return "부산"
    case .pohang:
      return "포항"
    case .seodaejeon:
      return "서대전"
    case .iksan:
      return "익산"
    case .jeongeup:
      return "정읍"
    case .gwangjuSongjeong:
      return "광주송정"
    case .naju:
      return "나주"
    case .mokpo:
      return "목포"
    case .jeonju:
      return "전주"
    case .namwon:
      return "남원"
    case .suncheon:
      return "순천"
    case .yeosuExpo:
      return "여수EXPO"
    case .dongdaegu:
      return "동대구"
    case .daejeon:
      return "대전"
    case .gangneung:
      return "강릉"
    case .cheongnyangri:
      return "청량리"
    case .manjong:
      return "만종"
    case .pyeongchang:
      return "평창"
    }
  }

  public var homeTitle: String {
    switch self {
    case .seoul:
      return "SEOUL"
    case .yongsan:
      return "YONGSAN"
    case .gwangmyeong:
      return "광명"
    case .cheonanAsan:
      return "천안아산"
    case .osong:
      return "오송"
    case .gimcheonGumi:
      return "김천(구미)"
    case .gyeongju:
      return "경주"
    case .ulsan:
      return "울산"
    case .busan:
      return "BUSAN"
    case .pohang:
      return "포항"
    case .seodaejeon:
      return "서대전"
    case .iksan:
      return "익산"
    case .jeongeup:
      return "정읍"
    case .gwangjuSongjeong:
      return "광주송정"
    case .naju:
      return "나주"
    case .mokpo:
      return "목포"
    case .jeonju:
      return "전주"
    case .namwon:
      return "남원"
    case .suncheon:
      return "순천"
    case .yeosuExpo:
      return "여수EXPO"
    case .dongdaegu:
      return "DONGDAEGU"
    case .daejeon:
      return "DAEJEON"
    case .gangneung:
      return "GANGNEUNG"
    case .cheongnyangri:
      return "CHEONGNYANGNI"
    case .manjong:
      return "만종"
    case .pyeongchang:
      return "평창"
    }
  }

  public init?(displayName: String) {
    let normalized = displayName
      .replacingOccurrences(of: "역", with: "")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    switch normalized {
    case "서울":
      self = .seoul
    case "용산":
      self = .yongsan
    case "광명":
      self = .gwangmyeong
    case "천안아산":
      self = .cheonanAsan
    case "오송":
      self = .osong
    case "김천(구미)":
      self = .gimcheonGumi
    case "경주":
      self = .gyeongju
    case "울산":
      self = .ulsan
    case "부산":
      self = .busan
    case "포항":
      self = .pohang
    case "서대전":
      self = .seodaejeon
    case "익산":
      self = .iksan
    case "정읍":
      self = .jeongeup
    case "광주송정":
      self = .gwangjuSongjeong
    case "나주":
      self = .naju
    case "목포":
      self = .mokpo
    case "전주":
      self = .jeonju
    case "남원":
      self = .namwon
    case "순천":
      self = .suncheon
    case "여수EXPO":
      self = .yeosuExpo
    case "동대구":
      self = .dongdaegu
    case "대전":
      self = .daejeon
    case "강릉":
      self = .gangneung
    case "청량리":
      self = .cheongnyangri
    case "만종":
      self = .manjong
    case "평창":
      self = .pyeongchang
    default:
      return nil
    }
  }
}
