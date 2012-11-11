//
//  CMUDViewController.m
//  CMUnistrokeDemo
//
//  Created by Chris Miles on 23/09/12.
//  Copyright (c) 2012 Chris Miles. All rights reserved.
//
//  MIT Licensed (http://opensource.org/licenses/mit-license.php):
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CMUDViewController.h"
#import "CMUDTemplatePaths.h"
#import "CMUDStrokeTemplateView.h"
#import "CMUDOptionsViewController.h"
#import "CMUDAddTemplateViewController.h"
#import "CMUDShared.h"


@interface CMUDViewController ()

@property (weak, nonatomic) IBOutlet UIButton *addTemplateButton;
@property (weak, nonatomic) IBOutlet CMUDDrawView *drawView;
@property (weak, nonatomic) IBOutlet UILabel *recognizedTemplateLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *templatesScrollView;

@property (strong, nonatomic) NSDictionary *templateViews;

@end


@implementation CMUDViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(templateGesturesShouldReloadNotification:) name:CMUDTemplateGesturesShouldReloadNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupStrokeTemplates];
    self.addTemplateButton.hidden = YES;
}

- (void)setupStrokeTemplates
{
    [self addStrokeTemplates];
    [self setupTemplatesScrollView];
    [self clearRecognizedTemplateLabel];
}

- (void)addStrokeTemplates
{
    [self.drawView clearAllUnistrokes];
    
    NSMutableDictionary *templateViews = [NSMutableDictionary dictionary];
    
    for (unsigned int i=0; ; i++) {
	struct templatePath templatePath = templatePaths[i];
	if (templatePath.length == 0) break;
	
	UIBezierPath *bezierPath = [[UIBezierPath alloc] init];
	[bezierPath moveToPoint:templatePath.points[0]];
	for (NSUInteger j=1; j<templatePath.length; j++) {
	    [bezierPath addLineToPoint:templatePath.points[j]];
	}
	
	NSString *name = [NSString stringWithUTF8String:templatePath.name];
	[self.drawView registerUnistrokeWithName:name bezierPath:bezierPath];
	
	CMUDStrokeTemplateView *templateView = [[CMUDStrokeTemplateView alloc] initWithName:name bezierPath:bezierPath];
	[templateViews setObject:templateView forKey:name];
    }
    
    self.templateViews = templateViews;
}

- (void)templateGesturesShouldReloadNotification:(NSNotification *)notification
{
#pragma unused(notification)
    
    [self setupStrokeTemplates];
}

- (void)setupTemplatesScrollView
{
    [self.templatesScrollView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
#pragma unused(idx, stop)
	[(UIView *)obj removeFromSuperview];
    }];
    
    CGSize size = CGSizeMake(CGRectGetHeight(self.templatesScrollView.bounds), CGRectGetHeight(self.templatesScrollView.bounds));
    
    [[self.templateViews allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
#pragma unused(stop)
	CMUDStrokeTemplateView *templateView = obj;
	
	CGRect frame = CGRectMake(idx * size.width, 0.0f, size.width, size.height);
	templateView.frame = CGRectIntegral(CGRectInset(frame, 5.0f, 5.0f));
	[self.templatesScrollView addSubview:templateView];
    }];
    
    self.templatesScrollView.contentSize = CGSizeMake(size.width * [self.templateViews count], size.height);
}


#pragma mark - CMUDDrawViewDelegate methods

- (void)drawViewDidStartRecognizingStroke:(CMUDDrawView *)drawView
{
#pragma unused(drawView)
    [self clearRecognizedTemplateLabel];
    [self highlightTemplateView:nil];
    self.addTemplateButton.hidden = YES;
}

- (void)drawView:(CMUDDrawView *)drawView didRecognizeUnistrokeWithName:(NSString *)name score:(float)score
{
#pragma unused(drawView)
#pragma unused(score)
    
    CMUDStrokeTemplateView *templateView = [self.templateViews objectForKey:name];
    if (templateView) {
	[self.templatesScrollView scrollRectToVisible:templateView.frame animated:YES];
	[self highlightTemplateView:templateView];
    }
    
    [self updateRecognizedTemplateLabelWithName:name score:score];
    self.addTemplateButton.hidden = NO;
}

- (void)drawViewDidFailToRecognizeUnistroke:(CMUDDrawView *)drawView
{
#pragma unused(drawView)

    self.recognizedTemplateLabel.text = @"Not recognized";
    self.addTemplateButton.hidden = NO;
}


#pragma mark - Highlight template view

- (void)highlightTemplateView:(CMUDStrokeTemplateView *)highlightedTemplateView
{
    for (CMUDStrokeTemplateView *templateView in [self.templateViews allValues]) {
	if (templateView == highlightedTemplateView) {
	    templateView.highlighted = YES;
	}
	else if (templateView.isHighlighted) {
	    templateView.highlighted = NO;
	}
    }
}


#pragma mark - Recognized template label

- (void)updateRecognizedTemplateLabelWithName:(NSString *)name score:(float)score
{
    if (name) {
	self.recognizedTemplateLabel.text = [NSString stringWithFormat:@"Recognized: %@ (%0.0f%%)", name, score*100.0f];
    }
    else {
	self.recognizedTemplateLabel.text = nil;
    }
}

- (void)clearRecognizedTemplateLabel
{
    [self updateRecognizedTemplateLabelWithName:nil score:0.0f];
}


#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
#pragma unused(sender)
    
    if ([segue.identifier isEqualToString:@"RecognizerToOptions"]) {
	CMUDOptionsViewController *viewController = (CMUDOptionsViewController *)segue.destinationViewController;
	viewController.unistrokeGestureRecognizer = self.drawView.unistrokeGestureRecognizer;
    }
    else if ([segue.identifier isEqualToString:@"RecognizerToAddTemplate"]) {
	CMUDAddTemplateViewController *viewController = (CMUDAddTemplateViewController *)[(UINavigationController *)segue.destinationViewController topViewController];
	viewController.strokePath = self.drawView.drawPath;
	viewController.templateNames = [self.templateViews allKeys];
    }
}

@end