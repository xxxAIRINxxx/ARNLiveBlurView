ARNLiveBlurView
======================

[![Build Status](https://travis-ci.org/xxxAIRINxxx/ARNLiveBlurView.svg?branch=master)](https://travis-ci.org/xxxAIRINxxx/ARNLiveBlurView)

Blur Effect And observe ScrollView contentOffset.


Respect
============

It was inspired by the following products.

* [SVBlurView](https://github.com/TransitApp/SVBlurView)

* [DKLiveBlur](https://github.com/kronik/DKLiveBlur)

* UIImageEffects ( Apple WWDC 2013 )


Requirements
============

Requires iOS 7.0 or later, and uses ARC.


How To Use
============

### Blur at superView
```objectivec

    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    backgroundView.frame = self.view.bounds;
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:backgroundView];

    ARNLiveBlurView *blurView = [[ARNLiveBlurView alloc] initWithFrame:backgroundView.bounds];
    [backgroundView addSubview:blurView];

```

### Blur at selectView. And Observe
```objectivec

    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    backgroundView.frame       = self.view.bounds;
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:backgroundView];

    ARNLiveBlurView *blurView = [[ARNLiveBlurView alloc] initWithFrame:backgroundView.bounds];
    blurView.viewToBlur = backgroundView;
    [self.view addSubview:blurView];
    blurView.alpha = 0;

    self.tableView                  = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)) style:UITableViewStylePlain];
    // tableview Setting...
    [self.view addSubview:self.tableView];

    [blurView setObservingScrollView:self.tableView observingBlock: ^(ARNLiveBlurView *blurredView, UIScrollView *observingView) {
        // do anything....
    }];

```


Licensing
============

The source code is distributed under the nonviral MIT License.

 It's the simplest most permissive license available.


Japanese Note
============

UIViewのブラー処理用のクラスです。
