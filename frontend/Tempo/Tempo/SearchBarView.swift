//
//  SearchBarView.swift
//  Tempo
//
//  Created by Casey Wentland on 4/4/22.
//

import SwiftUI

struct SearchBarView: View {
    
    @Binding var searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(
                searchText.isEmpty ? Color.secondary : Color.accentColor)
            
            TextField("Search for nearby events...", text: $searchText)
                .foregroundColor(Color.accentColor)
                .overlay(
                    Image(systemName: "xmark.circle.fill")
                        .padding()
                        .offset(x: 10)
                        .foregroundColor(Color.accentColor)
                        .opacity(searchText.isEmpty ? 0.0 : 1.0)
                        .onTapGesture {
                            searchText = ""
                        }
                    ,alignment: .trailing
                )
            
        }
        .font(.headline)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white)
                .shadow(
                    color: Color.accentColor.opacity(0.15),
                    radius: 10, x:0, y:0)
        )
        .padding()
    }
}

