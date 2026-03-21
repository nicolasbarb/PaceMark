//
//  ProBadge.swift
//  trailmark
//
//  Created by Nicolas Barbosa on 21/03/2026.
//

import SwiftUI

struct ProBadge: View {
    
    var isLockVisible: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            if isLockVisible {
                Image(systemName: "lock.fill")
            }
            Text("PRO")
        }
        .font(.system(size: 9, weight: .bold, design: .monospaced))
        .foregroundStyle(.white)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(TM.accent, in: RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    VStack {
        ProBadge(isLockVisible: true)
        ProBadge(isLockVisible: false)
    }
}
