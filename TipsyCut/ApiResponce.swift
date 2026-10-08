//
//  ApiResponce.swift
//  TipsyCut
//
//  Created by ㅇㅁㄹ on 9/20/26.
//

// ApiResponse.swift
import Foundation

struct ApiResponse<T: Decodable>: Decodable {
    let success: Bool?
    let message: String?
    let data: T?
}
