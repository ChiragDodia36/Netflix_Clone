//
//  SearchFiltersView.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import SwiftUI

struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    let onApply: () -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var tempFilters: SearchFilters
    
    init(filters: Binding<SearchFilters>, onApply: @escaping () -> Void) {
        self._filters = filters
        self.onApply = onApply
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Content Type Filter
                    FilterSection(title: "Content Type") {
                        VStack(spacing: 12) {
                            ForEach(ContentType.allCases, id: \.self) { type in
                                FilterOption(
                                    title: type.rawValue,
                                    isSelected: tempFilters.contentType == type
                                ) {
                                    tempFilters.contentType = type
                                }
                            }
                        }
                    }
                    
                    // Genre Filter
                    FilterSection(title: "Genres") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SearchService.availableGenres, id: \.self) { genre in
                                FilterChip(
                                    title: genre,
                                    isSelected: tempFilters.selectedGenres.contains(genre)
                                ) {
                                    if tempFilters.selectedGenres.contains(genre) {
                                        tempFilters.selectedGenres.removeAll { $0 == genre }
                                    } else {
                                        tempFilters.selectedGenres.append(genre)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Rating Filter
                    FilterSection(title: "Content Rating") {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SearchService.availableRatings, id: \.self) { rating in
                                FilterChip(
                                    title: rating,
                                    isSelected: tempFilters.selectedRatings.contains(rating)
                                ) {
                                    if tempFilters.selectedRatings.contains(rating) {
                                        tempFilters.selectedRatings.removeAll { $0 == rating }
                                    } else {
                                        tempFilters.selectedRatings.append(rating)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Year Range Filter
                    FilterSection(title: "Release Year") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("From")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Picker("Min Year", selection: $tempFilters.minYear) {
                                    Text("Any").tag(nil as Int?)
                                    ForEach(SearchService.yearRange.reversed(), id: \.self) { year in
                                        Text("\(year)").tag(year as Int?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("To")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Picker("Max Year", selection: $tempFilters.maxYear) {
                                    Text("Any").tag(nil as Int?)
                                    ForEach(SearchService.yearRange.reversed(), id: \.self) { year in
                                        Text("\(year)").tag(year as Int?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Duration Filter
                    FilterSection(title: "Duration (minutes)") {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Min Duration")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Picker("Min Duration", selection: $tempFilters.minDuration) {
                                    Text("Any").tag(nil as Int?)
                                    ForEach(Array(stride(from: 30, through: 300, by: 30)), id: \.self) { duration in
                                        Text("\(duration) min").tag(duration as Int?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .foregroundColor(.white)
                            }
                            
                            HStack {
                                Text("Max Duration")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Picker("Max Duration", selection: $tempFilters.maxDuration) {
                                    Text("Any").tag(nil as Int?)
                                    ForEach(Array(stride(from: 30, through: 300, by: 30)), id: \.self) { duration in
                                        Text("\(duration) min").tag(duration as Int?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .foregroundColor(.white)
                            }
                        }
                    }
                    
                    
                    // Active Filters Summary
                    if tempFilters.hasActiveFilters {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Filters")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                if tempFilters.contentType != .all {
                                    FilterTag(title: "Type: \(tempFilters.contentType.rawValue)") {
                                        tempFilters.contentType = .all
                                    }
                                }
                                
                                ForEach(tempFilters.selectedGenres, id: \.self) { genre in
                                    FilterTag(title: genre) {
                                        tempFilters.selectedGenres.removeAll { $0 == genre }
                                    }
                                }
                                
                                ForEach(tempFilters.selectedRatings, id: \.self) { rating in
                                    FilterTag(title: rating) {
                                        tempFilters.selectedRatings.removeAll { $0 == rating }
                                    }
                                }
                                
                                if let minYear = tempFilters.minYear {
                                    FilterTag(title: "From \(minYear)") {
                                        tempFilters.minYear = nil
                                    }
                                }
                                
                                if let maxYear = tempFilters.maxYear {
                                    FilterTag(title: "To \(maxYear)") {
                                        tempFilters.maxYear = nil
                                    }
                                }
                                
                                if let minDuration = tempFilters.minDuration {
                                    FilterTag(title: "Min \(minDuration) min") {
                                        tempFilters.minDuration = nil
                                    }
                                }
                                
                                if let maxDuration = tempFilters.maxDuration {
                                    FilterTag(title: "Max \(maxDuration) min") {
                                        tempFilters.maxDuration = nil
                                    }
                                }
                                
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Reset") {
                    tempFilters.reset()
                }
                .foregroundColor(.red)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Apply") {
                    // Update the main filters with tempFilters
                    filters = tempFilters
                    // Call the onApply callback
                    onApply()
                    // Dismiss the sheet
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.red)
                .fontWeight(.semibold)
            }
        }
    }
    
    
    // MARK: - Filter Section
    
    struct FilterSection<Content: View>: View {
        let title: String
        let content: Content
        
        init(title: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                content
            }
        }
    }
    
    // MARK: - Filter Option
    
    struct FilterOption: View {
        let title: String
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.red.opacity(0.2) : Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Filter Chip
    
    struct FilterChip: View {
        let title: String
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? Color.red.opacity(0.8) : Color.gray.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
    }
    
    // MARK: - Filter Tag
    
    struct FilterTag: View {
        let title: String
        let onRemove: () -> Void
        
        var body: some View {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red.opacity(0.8))
            )
        }
    }
    
    // Preview
    struct SearchFiltersView_Previews: PreviewProvider {
        static var previews: some View {
            SearchFiltersView(filters: .constant(SearchFilters())) {
                // Apply action
            }
        }
    }
}
