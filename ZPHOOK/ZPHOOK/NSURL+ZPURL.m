//
//  NSURL+ZPURL.m
//  方法欺骗
//
//  Created by 赵鹏 on 2018/12/14.
//  Copyright © 2018 赵鹏. All rights reserved.
//

/**
 如果觉得iOS原生类里面的系统方法写的不好或者需要根据实际需求往里面加入新代码的话，有如下的两种实现方式：
 1、创建这个原生类的分类(Category)，在这个分类的.m文件中重写那个系统的原生方法。由于分类里面的方法的优先级比较高，所以可以覆盖掉那个系统的原生方法；
 2、利用Runtime机制在分类中的.m文件中创建一个新的方法，在这个新的方法中撰写新的代码，然后在该文件的"load"方法中利用Runtime机制的"class_getClassMethod"函数把要修改的系统的原生方法替换成新创建的那个方法即可。通过这个函数交换两个SEL和IMP对应关系的技术，我们称之为Method Swizzle（方法欺骗）。

 在分类的方法中，不可以调用super方法。
 */
#import "NSURL+ZPURL.h"
#import <objc/message.h>

@implementation NSURL (ZPURL)

#pragma mark ————— 上述的第一种方式 —————
//系统会给一个警告，是正常现象。
//+ (nullable instancetype)URLWithString:(NSString *)URLString
//{
//    NSLog(@"分类里面重写系统的原生方法");
//
//    static int a = 0;
//    NSURL *url = nil;
//    if (a == 0)
//    {
//        a++;
//        url = [NSURL URLWithString:URLString];
//    }
//
//    return url;
//}

#pragma mark ————— 上述的第二种方式 —————
+ (void)load
{
    /**
     用"class_getClassMethod"函数来获取系统的原生类方法：
     Method可以理解为方法，是一个结构体指针，包含SEL（方法编号）和IMP（方法实现的地址）。
     */
    Method protogeneticUrl = class_getClassMethod(self, @selector(URLWithString:));
    
    /**
     用"class_getInstanceMethod"函数来获取系统的原生实例方法：
     */
//    Method protogeneticUrl = class_getInstanceMethod(<#Class  _Nullable __unsafe_unretained cls#>, <#SEL  _Nonnull name#>)
    
    /**
     用"class_getClassMethod"函数来获取新创建的类方法
     */
    Method newUrl = class_getClassMethod(self, @selector(ZPURLWithString:));
    
    /**
     正常情况下，在程序里面调用"URLWithString:"方法以后，系统会根据SEL（方法编号）"URLWithString:"去找这个SEL相对应的IMP（方法实现的地址），然后根据这个指针的指向找到这个方法的实现，再进行调用。想要在程序中调用"URLWithString:"方法的时候执行其他方法的话就要调用Runtime机制内的"method_exchangeImplementations"函数，使这个函数中的两个方法的IMP相互调换，然后程序在调用"URLWithString:"方法的时候根据这个SEL找到IMP是存储新方法实现的地址，然后根据这个IMP找到的是新方法的实现，再进行调用，从而实现了方法调用的交换。
     */
    method_exchangeImplementations(protogeneticUrl, newUrl);
}

/**
 为了防止"URLWithString:"后面的参数带有中文，所以当程序调用"URLWithString:"方法的时候，让系统执行下面的这个方法来进行过滤和处理。
 */
+ (instancetype)ZPURLWithString:(NSString *)str
{
    NSLog(@"方法调换");
    
    /**
     因为在"load"方法中做了方法交换，所以当调用"ZPURLWithString:"方法的时候，实际上调用的是系统的原生方法"URLWithString:"。
     */
    NSURL *url = [NSURL ZPURLWithString:str];
    
    if (url == nil)
    {
        str = [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];  //对中文进行编码
    }
    
    url = [NSURL ZPURLWithString:str];
    
    return url;
}


@end
