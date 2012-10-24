//
//  MBRowViewBuilder 
//
//  Created by Pieter Kuijpers on 13-08-12.
//  Copyright (c) 2012 Itude Mobile. All rights reserved.
//

#import "MBTypes.h"

@class MBComponentContainer;

/**
* Constructs UITableViewCells for MBRows. Implement this interface for custom UITableViewCells.
*/
@protocol MBRowViewBuilder <NSObject>
- (UITableViewCell *)buildTableViewCellFor:(MBComponentContainer *)component forIndexPath:(NSIndexPath *)indexPath viewState:(MBViewState)viewState
                     forTableView:(UITableView *)tableView;
- (CGFloat)heightForComponent:(MBComponentContainer *)component atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView;
@end