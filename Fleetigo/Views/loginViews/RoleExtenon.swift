//
//  RoleExtenon.swift
//  Fleetigo
//
//  Created by Deeptanshu Pal on 05/05/25.
//

import SwiftUI

extension Role {
    var color: Color {
        switch self {
        case .admin:
            return Color.red
        case .driver:
            return Color.blue
        case .maintenance:
            return Color.orange
        }
    }
}
