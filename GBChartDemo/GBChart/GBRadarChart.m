//
//  GBRadarChart.m
//  GBChartDemo
//
//  Created by midas on 2018/12/11.
//  Copyright © 2018 Midas. All rights reserved.
//

#import "GBRadarChart.h"
#import "GBRadarChartDataItem.h"

@interface GBRadarChart ()

@property (nonatomic) CGFloat centerX;//中心的x
@property (nonatomic) CGFloat centerY;//中心的y
@property (nonatomic) NSMutableArray *pointsToWebArrayArray;
@property (nonatomic) NSMutableArray *pointsToPlotArray;
@property (nonatomic) UILabel *detailLabel;//
@property (nonatomic) CGFloat lengthUnit;//每个单元的长度
@property (nonatomic) CAShapeLayer *chartPlot;
@property (nonatomic) NSMutableArray <UILabel *> *titleLabels;
@property (nonatomic) NSInteger tapTag;//点击的标签

@end

@implementation GBRadarChart

- (id)initWithFrame:(CGRect)frame items:(NSArray<GBRadarChartDataItem *> *)items valueDivider:(CGFloat)unitValue {
    
    if (self = [super initWithFrame:frame]) {
        
        _chartData = items;
        _valueDivider = unitValue;
        [self configDefaultValues];
    }
    return self;
}

- (void)configDefaultValues {
    
    self.backgroundColor = [UIColor whiteColor];
    _maxValue = 1;
    _webColor = [UIColor grayColor];
    _plotFillColor = [UIColor colorWithRed:.4 green:.8 blue:.4 alpha:.7];
    _plotStrokeColor = [UIColor colorWithRed:.4 green:.8 blue:.4 alpha:1.0];
    _fontColor = [UIColor blackColor];
    _graduationColor = [UIColor orangeColor];
    _fontSize = 12;
    _isLabelTouchable = YES;
    _isShowGraduation = NO;
    _displayAnimated = YES;
    //私有变量
    _centerX = self.bounds.size.width/2;
    _centerY = self.bounds.size.height/2;
    _pointsToWebArrayArray = [NSMutableArray array];
    _pointsToPlotArray = [NSMutableArray array];
    _titleLabels = [NSMutableArray array];
    _lengthUnit = 0;
    _chartPlot = [CAShapeLayer layer];
    _chartPlot.lineCap = kCALineCapButt;
    _chartPlot.lineWidth = 1.0;
    _chartPlot.frame = self.bounds;
    [self.layer addSublayer:_chartPlot];
    
    //init detailLabel
    _detailLabel = [[UILabel alloc] init];
    _detailLabel.backgroundColor = [UIColor grayColor];
    _detailLabel.textAlignment = NSTextAlignmentCenter;
    _detailLabel.textColor = [UIColor whiteColor];
    _detailLabel.font = [UIFont systemFontOfSize:14];
    [_detailLabel setHidden:YES];
    [self addSubview:_detailLabel];
}

#pragma mark - 计算要绘制的点
- (void)calculateChartPoints {
    
    [self.pointsToPlotArray removeAllObjects];
    [self.pointsToWebArrayArray removeAllObjects];
    [_chartPlot removeAllAnimations];
    for (UILabel*l in self.titleLabels) {
        [l removeFromSuperview];
    }
    [self.titleLabels removeAllObjects];
    
    NSMutableArray *values = [NSMutableArray array];
    NSMutableArray *descriptions = [NSMutableArray array];
    NSMutableArray *angles = [NSMutableArray array];
    for (int i = 0; i < _chartData.count; i++) {
        
        GBRadarChartDataItem *item = _chartData[i];
        [values addObject:@(item.value)];
        [descriptions addObject:item.textDescription];
        CGFloat angleValue = i * M_PI*2/_chartData.count;
        [angles addObject:@(angleValue)];
    }
    _maxValue = [self getMaxValueFromValues:values];
    //总共有多少个圆圈
    NSInteger plotCircles = _maxValue/_valueDivider;
    //计算折线图从圆点到顶点的最大的长度
    CGFloat maxWidthOfLabel = [self getMaxWidthForLabelFrom:descriptions];
    CGFloat maxLength = ceil(MIN(_centerX, _centerY) - maxWidthOfLabel);
    NSLog(@"maxLength = %f", maxLength);
    //每一段的平均长度
    _lengthUnit = maxLength/plotCircles;
    //总共的长度数组
    NSArray *lengthArray = [self getLengthArrayWithCircleNum:plotCircles];
    //获取所有的点
    for (NSNumber *length in lengthArray) {
        
        [self.pointsToWebArrayArray addObject:[self getWebPointsArrayWithLength:length.floatValue angles:angles]];
    }
    _pointsToPlotArray = [self getPlotPointsArrayWithValues:values angles:angles];
    
    //创建label
    [self createLabelWithMaxLength:maxLength descriptions:descriptions angleArray:angles];
}

#pragma mark - 获取折线图的点
- (NSMutableArray *)getPlotPointsArrayWithValues:(NSArray *)values angles:(NSArray *)angles {
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < values.count; i++) {
        CGFloat value = [values[i] floatValue];
        CGFloat angle = [angles[i] floatValue];
        CGFloat length = value * _lengthUnit / _valueDivider;
        CGFloat x = _centerX + length * sinf(angle);
        CGFloat y = _centerY + length * cosf(angle);
        [array addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
    }
    return array;
}

#pragma mark - 获取label最大的宽度
- (CGFloat)getMaxWidthForLabelFrom:(NSArray *)descriptions {
    
    CGFloat maxWidth = 0;
    for (int i = 0; i < descriptions.count; i++) {
        NSString *desc = descriptions[i];
        
        CGFloat w = [desc sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:_fontSize]}].width;
        maxWidth = MAX(maxWidth, w);
    }
    return maxWidth;
}

#pragma mark - 获取多个多边形点数组的数组
- (NSArray *)getWebPointsArrayWithLength:(CGFloat)length angles:(NSArray *)angles {
    
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < angles.count; i++) {
        CGFloat angleValue = [angles[i] floatValue];
        CGFloat x = _centerX + length*sinf(angleValue);
        CGFloat y = _centerY + length*cosf(angleValue);
        [array addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
    }
    return array;
}
#pragma mark - 获取射线长度数组
- (NSArray *)getLengthArrayWithCircleNum:(NSInteger)plotCircles {
    
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < plotCircles; i++) {
        
        [array addObject:@(_lengthUnit*(i+1))];
    }
    return array;
}

#pragma mark - 点击label
- (void)tapLabel:(UITapGestureRecognizer *)gesture {
    
    UILabel *label = (UILabel *)gesture.view;
    NSInteger tag = label.tag;
    if (tag != _tapTag) {
        _detailLabel.hidden = YES;
        _tapTag = tag;
    }
    CGRect frame = label.frame;
    _detailLabel.hidden = !_detailLabel.hidden;
    _detailLabel.text = [NSString stringWithFormat:@"%.2f",_chartData[tag].value];
    
    CGSize size = [_detailLabel.text sizeWithAttributes:@{NSFontAttributeName: _detailLabel.font}];
    size = CGSizeMake(size.width + 5, size.height + 2);
    _detailLabel.frame = CGRectMake(frame.origin.x, frame.origin.y- size.height -4, size.width, size.height);
}

#pragma mark - 创建label
- (void)createLabelWithMaxLength:(CGFloat)maxLength descriptions:(NSArray *)descriptions angleArray:(NSArray *)angleArray {
    
    NSInteger section = 0;
    for (NSString *desc in descriptions) {
        UILabel *label = [UILabel new];
        label.textColor = _fontColor;
        label.font = [UIFont systemFontOfSize:_fontSize];
        [self addSubview:label];
        [self.titleLabels addObject:label];
        if (_isLabelTouchable) {
            label.userInteractionEnabled = YES;
            label.tag = section;
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapLabel:)];
            [label addGestureRecognizer:tap];
        }
        label.text = desc;
        CGSize size = [desc sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:_fontSize]}];
        CGFloat angleValue = [angleArray[section] floatValue];
        CGFloat x = _centerX + maxLength*sin(angleValue);
        CGFloat y = _centerY + maxLength*cos(angleValue);
        if (angleValue == 0) {
            x -= size.width/2;
        } else if (angleValue > 0 && angleValue < M_PI_2) {

        } else if (angleValue == M_PI_2) {
            y -= size.height/2;
        } else if (angleValue > M_PI_2 && angleValue < M_PI) {
            y -= size.height;
        } else if (angleValue - M_PI < 0.01) {
            
            x -= size.width/2;
            y -= size.height;
        } else if (angleValue > M_PI && angleValue < 1.5 * M_PI) {
            
            x -= size.width;
            y -= size.height;
        } else if (angleValue - 1.5 * M_PI < 0.01) {
            x -= size.width;
            y -= size.height/2;
        } else {
        
            x -= size.width;
        }
        label.frame = CGRectMake(x, y, size.width, size.height);
        section++;
    }
}

#pragma mark - 获取最大的值
- (CGFloat)getMaxValueFromValues:(NSArray *)values {

    CGFloat maxValue = _maxValue;
    for (NSNumber *v in values) {
        
        maxValue = MAX(maxValue, v.floatValue);
    }
    return maxValue;
}

#pragma mark - 绘制图表
- (void)strokeChart {
    
    [self calculateChartPoints];
    [self setNeedsDisplay];
    [self drawPlotLayer];
    if (_displayAnimated) {
        [self addAnimationIfNeeded];
    }
    if (_isShowGraduation) {
        [self showGraduation];
    }
}

#pragma mark - 显示刻度label
- (void)showGraduation {
    
    for (int i = 1; i <= _pointsToWebArrayArray.count; i++) {
        
        CGPoint point = [_pointsToWebArrayArray[i-1][0] CGPointValue];
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:11];
        label.textColor = _graduationColor;
        label.text = [NSString stringWithFormat:@"%.0f", _valueDivider*i];
        label.frame = CGRectMake(point.x, point.y-6, 20, 12);
        [self addSubview:label];
    }
}

#pragma mark - 更新图表
- (void)updateChartWithChartData:(NSArray *)chartData {
    
    _chartData = chartData;
    [self strokeChart];
}

#pragma mark - 绘制范围图
- (void)drawPlotLayer {
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = 1;
    path.lineCapStyle = kCGLineCapButt;

    for (int i = 0; i < _pointsToPlotArray.count; i++) {
        CGPoint point = [_pointsToPlotArray[i] CGPointValue];
        if (i == 0) {
            [path moveToPoint:point];
        }
        [path addLineToPoint:point];
    }
    [path closePath];
    _chartPlot.fillColor = _plotFillColor.CGColor;
    _chartPlot.strokeColor = _plotStrokeColor.CGColor;
    _chartPlot.path = path.CGPath;
}

#pragma mark - 动画
- (void)addAnimationIfNeeded {
    
    CABasicAnimation *ani1 = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    ani1.fromValue = @0;
    ani1.toValue = @1.0;

    CABasicAnimation *ani2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    ani2.fromValue = @0;
    ani2.toValue = @1.0;

    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.animations = @[ani1, ani2];
    group.duration = 0.8;

    [_chartPlot addAnimation:group forKey:nil];
}


#pragma mark - 绘制
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, _webColor.CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor clearColor].CGColor);
    CGContextSetLineWidth(ctx, 1);
    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    
    for (int i = 0; i < _pointsToWebArrayArray.count; i++) {
        NSArray *pointToWebArray = _pointsToWebArrayArray[i];
        for (int j = 0; j < pointToWebArray.count; j++) {
            CGPoint point = [pointToWebArray[j] CGPointValue];
            if (j == 0) {
                CGContextMoveToPoint(ctx, point.x, point.y);
            }
            CGContextAddLineToPoint(ctx, point.x, point.y);
        }
        CGContextClosePath(ctx);
    }
    
    NSArray *lastPointsToWebArray = _pointsToWebArrayArray.lastObject;
    for (int i = 0; i < lastPointsToWebArray.count; i++) {
        
        CGPoint point = [lastPointsToWebArray[i] CGPointValue];
        CGContextMoveToPoint(ctx, _centerX, _centerY);
        CGContextAddLineToPoint(ctx, point.x, point.y);
    }
    
    CGContextStrokePath(ctx);
}

@end
