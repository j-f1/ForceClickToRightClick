//
//  ContentView.swift
//  ForceClickToRightClick
//
//  Created by Jed Fox on 5/11/21.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
      HStack(spacing: 0) {
        Color.gray
          .overlay(Text("Left Click"))
        Color(NSColor.lightGray)
          .overlay(Text("Right Click"))
      }
      .font(.title)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
