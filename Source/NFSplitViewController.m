//
//  NFSplitViewController.m
//  SplitView
//
//  Created by Alexander Cohen on 2014-10-28.
//  Copyright (c) 2014 BedroomCode. All rights reserved.
//

#import "NFSplitViewController.h"
#import "NFLayerBackedView.h"

@interface NFSplitViewControllerView : NFLayerBackedView

@property (nonatomic,assign) CGFloat vc2SizeBeforeCollpase;
@property (nonatomic,strong) NSMutableIndexSet* collapsedIndexes;
@property (nonatomic,weak) NFSplitViewController* controller;

@end

@implementation NSViewController (NFSplitViewControllerView)

- (CGFloat)minimumWidthInSplitViewController:(NFSplitViewController*)splitViewController
{
    return 0;
}

- (CGFloat)maximumWidthInSplitViewController:(NFSplitViewController*)splitViewController
{
    return MAXFLOAT;
}

- (BOOL)canCollapseInSplitViewController:(NFSplitViewController*)splitViewController
{
    return YES;
}

- (NFSplitViewController*)splitViewController
{
    if ( [self.parentViewController isKindOfClass:[NFSplitViewController class]] )
        return (NFSplitViewController*)self.splitViewController;
    return nil;
}

@end

@implementation NFSplitViewControllerView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    _collapsedIndexes = [NSMutableIndexSet indexSet];
    return self;
}

- (CGRect)_splitterRect
{
    if ( self.controller.childViewControllers.count < 2 )
        return CGRectZero;
    
    NSUInteger          numController = self.controller.childViewControllers.count;
    NSViewController*   vc1 = numController > 0 ? self.controller.childViewControllers[0] : nil;
    
    return CGRectMake( CGRectGetMaxX(vc1.view.frame)-2, 0, [NFSplitViewController dividerThickness]+4, self.bounds.size.height );
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // not 1 click
    if ( theEvent.clickCount > 1 )
    {
        [super mouseDown:theEvent];
        return;
    }
    
    // do we have at least 2 vc's
    if ( self.controller.childViewControllers.count != 2 )
    {
        [super mouseDown:theEvent];
        return;
    }
    
    // not in resize cursor
    if ( !CGRectContainsPoint( [self _splitterRect], [self convertPoint:theEvent.locationInWindow fromView:nil] ) )
    {
        [super mouseDown:theEvent];
        return;
    }
    
    CGPoint locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
    CGFloat offsetX = locationInView.x - [self _splitterRect].origin.x;
    
    // do the event pump drag
    BOOL pumpEvents = YES;
    while ( pumpEvents )
    {
        theEvent = [self.window nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        
        switch ( theEvent.type )
        {
            case NSLeftMouseDragged:
            {
                locationInView = [self convertPoint:theEvent.locationInWindow fromView:nil];
                NSView* v = [self.controller.childViewControllers[0] view];
                CGRect r = v.frame;
                r.size.width = locationInView.x - offsetX;
                v.frame = r;
                [self setNeedsLayout:YES];
                [self layoutSubtreeIfNeeded];
            }
                break;
                
            case NSLeftMouseUp:
            {
                [self setNeedsLayout:YES];
                [self layoutSubtreeIfNeeded];
                [self.window invalidateCursorRectsForView:self];
                
                pumpEvents = NO;
            }
                break;
                
            default:
            {
            }
                break;
        }
    }
}

- (void)resetCursorRects
{
    [super resetCursorRects];
    
    NSCursor* cursor = [NSCursor resizeLeftRightCursor];
    [cursor setOnMouseEntered:YES];
    
    [self addCursorRect: [self _splitterRect] cursor:cursor];
}

- (void)_performLayoutAnimated:(BOOL)animated resetBasedOnVC2:(BOOL)resetBasedOnVC2
{
    NSViewController*   vc1 = [self viewControllerAtIndex:0];
    NSViewController*   vc2 = [self viewControllerAtIndex:1];
    
    CGFloat             min1 = vc1 ? [vc1 minimumWidthInSplitViewController:self.controller] : 0;
    CGFloat             min2 = vc2 ? [vc2 minimumWidthInSplitViewController:self.controller] : 0;
    CGFloat             max1 = vc1 ? [vc1 maximumWidthInSplitViewController:self.controller] : 0;
    CGFloat             max2 = vc2 ? [vc2 maximumWidthInSplitViewController:self.controller] : 0;
    
    CGRect              frame1 = vc1.view.frame;
    CGRect              frame2 = vc2.view.frame;
    
    BOOL                vc1IsCollapsed = [self isViewControllerCollapsedAtIndex:0];
    BOOL                vc2IsCollapsed = [self isViewControllerCollapsedAtIndex:1];
    
    // set defaults
    if ( frame1.size.width < min1 )
        frame1.size.width = min1;
    if ( frame1.size.width > max1 )
        frame1.size.width = max1;
    
    if ( frame2.size.width < min2 )
        frame2.size.width = min2;
    if ( frame2.size.width > max2 )
        frame2.size.width = max2;
    
    // setup frame 1
    frame1.origin.x = 0;
    frame1.origin.y = 0;
    frame1.size.height = self.bounds.size.height;
    if ( frame1.size.width > self.bounds.size.width - [NFSplitViewController dividerThickness] )
        frame1.size.width = self.bounds.size.width - [NFSplitViewController dividerThickness];
    
    if ( vc2IsCollapsed )
        frame1.size.width = self.bounds.size.width;
    else if ( resetBasedOnVC2 && !vc1IsCollapsed )
    {
        frame1.size.width = self.bounds.size.width - [NFSplitViewController dividerThickness] - self.vc2SizeBeforeCollpase;
    }
    
    // setup frame 2
    frame2.origin.x = vc1IsCollapsed ? 0 : CGRectGetMaxX(frame1) + [NFSplitViewController dividerThickness];
    frame2.origin.y = 0;
    frame2.size.width = vc1IsCollapsed ? self.bounds.size.width : self.bounds.size.width - CGRectGetMinX(frame2);
    frame2.size.height = self.bounds.size.height;
    
    // apply frames
    if ( animated )
    {
        [[vc1.view animator] setFrame:frame1];
        [[vc2.view animator] setFrame:frame2];
    }
    else
    {
        vc1.view.frame = frame1;
        vc2.view.frame = frame2;
    }
    
}

- (void)layout
{
    [self _performLayoutAnimated:NO resetBasedOnVC2:NO];
    [super layout];
}

- (NSViewController*)viewControllerAtIndex:(NSUInteger)index
{
    return self.controller.childViewControllers.count > index ? self.controller.childViewControllers[index] : nil;
}

- (void)collapseViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    NSViewController* vc = [self viewControllerAtIndex:index];
    if ( !vc || ![vc canCollapseInSplitViewController:self.controller] )
        return;
    
    if ( [self isViewControllerCollapsedAtIndex:index] )
    {
        [self.collapsedIndexes removeIndex:index];
        
        vc.view.hidden = NO;
        
        if ( animated )
        {
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [self _performLayoutAnimated:YES resetBasedOnVC2: index == 1];
            } completionHandler:^{
                
            }];
        }
        else
        {
            [self setNeedsLayout:YES];
            [self layoutSubtreeIfNeeded];
        }
        
    }
    else
    {
        [self.collapsedIndexes addIndex:index];
        
        if ( index == 1 )
            self.vc2SizeBeforeCollpase = vc.view.frame.size.width;
        
        if ( animated )
        {
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
                [self _performLayoutAnimated:YES resetBasedOnVC2:NO];
            } completionHandler:^{
                vc.view.hidden = YES;
            }];
        }
        else
        {
            vc.view.hidden = NO;
            [self setNeedsLayout:YES];
            [self layoutSubtreeIfNeeded];
        }
        
    }
}

- (BOOL)isViewControllerCollapsedAtIndex:(NSUInteger)index
{
    return [self.collapsedIndexes containsIndex:index];
}

@end

@interface NFSplitViewController ()

@property (nonatomic,assign) BOOL isInTransition;
@property (nonatomic,strong) NFSplitViewControllerView* splitView;

@end

@implementation NFSplitViewController

+ (CGFloat)dividerThickness
{
    return 1;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    return self;
}

- (void)loadView
{
    self.view = [[NFLayerBackedView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.splitView = [[NFSplitViewControllerView alloc] initWithFrame:self.view.bounds];
    self.splitView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.splitView.backgroundColor = [NSColor lightGrayColor];
    self.splitView.controller = self;
    [self.view addSubview:self.splitView];
    
    for ( NSViewController* cntlr in self.childViewControllers )
        [self.splitView addSubview:cntlr.view];
}

- (void)setSplitterColor:(NSColor *)splitterColor
{
    (void)self.view;
    self.splitView.backgroundColor = splitterColor;
}

- (NSColor*)splitterColor
{
    (void)self.view;
    return self.splitView.backgroundColor;
}

- (void)collapseViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    [self.splitView collapseViewControllerAtIndex:index animated:animated];
}

- (BOOL)isViewControllerCollapsedAtIndex:(NSUInteger)index
{
    return [self.splitView isViewControllerCollapsedAtIndex:index];
}

- (NSViewController*)viewControllerAtIndex:(NSUInteger)index
{
    return self.childViewControllers.count > index ? self.childViewControllers[index] : nil;
}

- (void)transitionFromViewControllerAtIndex:(NSUInteger)index toViewController:(NSViewController*)viewController
{
    if ( ![self viewControllerAtIndex:index] )
    {
        [self insertChildViewController:viewController atIndex:index];
    }
    else
    {
        self.isInTransition = YES;
        [self addChildViewController:viewController];
        NSViewController* srcVC = [self viewControllerAtIndex:index];
        viewController.view.frame = srcVC.view.frame;
        
        __weak typeof(self)weakMe = self;
        [self transitionFromViewController:srcVC toViewController:viewController options:NSViewControllerTransitionCrossfade completionHandler:^{
            typeof(self)me = weakMe;
            [srcVC removeFromParentViewController];
            me.isInTransition = NO;
        }];
    }
}

- (void)insertChildViewController:(NSViewController *)childViewController atIndex:(NSInteger)index
{
    if ( self.isInTransition )
    {
        [super insertChildViewController:childViewController atIndex:index];
        return;
    }
    
    NSAssert( self.childViewControllers.count < 2, @"A SplitViewController can only have 2 child view controllers", nil );
    
    [super insertChildViewController:childViewController atIndex:index];
    
    if ( ![self isViewLoaded] )
        return;
    
    NSView* rel = nil;
    if ( index > 0 )
        rel = self.splitView.subviews[index-1];
    
    [self.splitView addSubview:childViewController.view positioned:NSWindowAbove relativeTo:rel];
    [self.splitView setNeedsLayout:YES];
    [self.view.window invalidateCursorRectsForView:self.splitView];
}

- (void)removeChildViewControllerAtIndex:(NSInteger)index
{
    [super removeChildViewControllerAtIndex:index];
    
    if ( self.isInTransition || ![self isViewLoaded] )
        return;
    
    NSView* sub = self.splitView.subviews[index];
    [sub removeFromSuperview];
    [self.view.window invalidateCursorRectsForView:self.splitView];
}

@end