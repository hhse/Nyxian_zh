/*
 Copyright (C) 2025 cr4zyengineer

 This file is part of Nyxian.

 Nyxian is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Nyxian is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Nyxian. If not, see <https://www.gnu.org/licenses/>.
*/

#import <LindChain/Debugger/Logger.h>

static const CGFloat kAutoScrollThreshold = 20.0;

@implementation LogTextView {
    BOOL _followTail;
}

- (instancetype)init {
    return [self initWithPipe:[NSPipe pipe]];
}

- (instancetype)initWithPipe:(NSPipe*)pipe {
    if ((self = [super init])) {
        _pipe = pipe;
        _followTail = YES;

        self.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightBold];
        self.backgroundColor = [UIColor systemGray6Color];
        self.editable = NO;
        self.selectable = YES;
        self.text = @"";
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.alwaysBounceVertical = YES;

        self.delegate = (id<UITextViewDelegate>)self;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleNotification:)
                                                     name:NSFileHandleReadCompletionNotification
                                                   object:_pipe.fileHandleForReading];

        [_pipe.fileHandleForReading readInBackgroundAndNotify];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    @try {
        [_pipe.fileHandleForReading closeFile];
    } @catch (NSException *ex) { /* ignore */ }
    _pipe = nil;
}

- (void)handleNotification:(NSNotification*)notification {
    NSData *data = notification.userInfo[NSFileHandleNotificationDataItem];
    if (!data || data.length == 0) {
        [_pipe.fileHandleForReading readInBackgroundAndNotify];
        return;
    }

    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!output) {
        [_pipe.fileHandleForReading readInBackgroundAndNotify];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *attributes = @{
            NSFontAttributeName: [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightBold],
            NSForegroundColorAttributeName: [UIColor labelColor]
        };
        NSAttributedString *attr = [[NSAttributedString alloc] initWithString:output attributes:attributes];
        [self.textStorage appendAttributedString:attr];

        [self.layoutManager ensureLayoutForTextContainer:self.textContainer];

        if (self->_followTail) {
            CGPoint bottomOffset = CGPointMake(0, MAX(0, self.contentSize.height - self.bounds.size.height));
            [self setContentOffset:bottomOffset animated:NO];
        }
    });

    [_pipe.fileHandleForReading readInBackgroundAndNotify];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat distanceFromBottom = scrollView.contentSize.height - scrollView.bounds.size.height - scrollView.contentOffset.y;
    _followTail = (distanceFromBottom <= kAutoScrollThreshold);
}

@end
