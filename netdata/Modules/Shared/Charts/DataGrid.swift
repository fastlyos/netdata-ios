//
//  DataGrid.swift
//  netdata
//
//  Created by Arjun Komath on 25/7/20.
//

import SwiftUI

enum GridDataType {
    case percentage
    case absolute
}

struct DataGrid: View {
    var labels: [String]
    var data: [[Double]]
    var dataType: GridDataType
    var showArrows: Bool
    
    var body: some View {
        if labels.count > 1 {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: self.dataType == GridDataType.percentage ? 65 : 80))], alignment: .leading, spacing: 8) {
                ForEach(1..<self.labels.count) { i in
                    if self.dataType == .percentage {
                        PercentageUsageData(usage: CGFloat(self.data.first![i]),
                                            title: self.labels[i])
                    }
                    if self.dataType == .absolute {
                        AbsoluteUsageData(usage: CGFloat(self.data.first![i]),
                                          title: self.labels[i],
                                          showArrows: self.showArrows)
                    }
                }
            }
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 65))], spacing: 8) {
                ForEach((1...4), id: \.self) { _ in
                    AbsoluteUsageData(usage: 0.1,
                                      title: "loading",
                                      showArrows: false)
                        .redacted(reason: .placeholder)
                }
            }
        }
    }
}

struct DataGrid_Previews: PreviewProvider {
    static var previews: some View {
        DataGrid(labels: ["test", "test"],
                 data: [[5, 4]],
                 dataType: .absolute,
                 showArrows: false)
    }
}
