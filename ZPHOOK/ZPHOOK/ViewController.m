//
//  ViewController.m
//  ZPHOOK
//
//  Created by 赵鹏 on 2018/12/17.
//  Copyright © 2018 赵鹏. All rights reserved.
//

/**
 HOOK：中文译为“挂钩”或“钩子”。在iOS逆向中是指改变程序运行流程的一种技术，通过HOOK可以让别人的程序执行自己所写的代码。在逆向中经常使用这种技术。
 
 HOOK的几种实现方式：
 1、Method Swizzle（方法欺骗）：
 Runtime（运行时）机制也叫做消息发送机制，在OC中所有的方法调用都可以看做是消息发送；
 在Runtime中有两个重要的概念"SEL"和"IMP"，"SEL"是方法编号，"IMP"是方法实现的地址（函数指针）。"SEL"和"IMP"之间的关系，就好像一本书的目录，"SEL"是目录中左侧的标题，"IMP"是目录中右侧的页码，它们是一一对应的关系；
 利用OC的Runtime特性，动态改变"SEL"和"IMP"的对应关系，达到OC方法调用流程改变的目的；
 想要调用Runtime里面的函数就应该先在本类中引用它所依赖的库"<objc/message.h>"，然后在"TARGETS"中的"Build Settings"中搜索"msg"，在搜索结果中把"Enable Strict Checking of objc_msgSend Calls"由"Yes"改为"No"，否则无法调用相关的函数。
 2、fishhook：
 它是Facebook提供的一个动态修改链接MachO文件的工具。利用MachO文件的加载原理，通过修改懒加载和非懒加载两个表的指针达到C函数HOOK的目的。官方地址："https://github.com/facebook/fishhook"，通过这个官方地址下载下来的是"fishhook.c"和"fishhook.h"两个文件，把这两个文件放到项目中才能使用fishhook了；
 fishhook能HOOK系统的函数，但是不能HOOK自定义的函数。
 3、Cydia Substrate：
 Cydia Substrate原名为"Mobile Substrate"，它的主要作用是针对OC方法、C函数以及函数地址进行HOOK操作。当然它并不仅仅是针对iOS而设计的，安卓一样可以用。官方地址："http://www.cydiasubstrate.com/"。
 */
#import "ViewController.h"
#import "fishhook.h"

@interface ViewController ()

@end

@implementation ViewController

#pragma mark ————— 生命周期 —————
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //上述的第一种Method Swizzle（方法欺骗）
//    [self methodSwizzle];
    
    //上述的第二种fishhook实现方式
    [self fishhook];
}

#pragma mark ————— Method Swizzle —————
//上述的第一种Method Swizzle（方法欺骗）实现方式
- (void)methodSwizzle
{
    /**
     下面的代码可以看做是给"NSURL"这个类发送一个"URLWithString:"的消息。在下面的代码中可以把"URLWithString:"方法看做是"SEL"，当系统调用"URLWithString:"方法的时候，系统会根据这个"SEL"去找寻它所对应的"IMP"，也就是存储方法实现的地址，然后根据这个地址的指向，找到这个方法的实现，并且调用它。
     */
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com/新闻"];
    
    /**
     上面的代码可以利用Runtime机制改写成下面的样式。下面代码的意思是给"NSURL"这个类发送一个"URLWithString:"的消息，参数为"https://www.baidu.com"。
     */
//    NSURL *url = objc_msgSend([NSURL class], @selector(URLWithString:), @"https://www.baidu.com");
//    NSLog(@"url = %@", url);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSLog(@"%@", request);
}

#pragma mark ————— fishhook —————
//上述的第二种fishhook实现方式
- (void)fishhook
{
    /**
     创建rebinding结构体：
     "rebinding"是fishhook提供的一种结构体。
     */
    struct rebinding nslog;
    nslog.name = "NSLog";  //name：需要交换的原来的函数名称或者C字符串
    nslog.replacement = myNslog;  //replacement：需要交换的新函数的名称或者C字符串
    nslog.replaced = (void *)&sys_nslog;  //replaced：把原始函数的指针保存到里面去
    
    //创建"rebinding"结构体数组：
    struct rebinding rebs[1] = {nslog};
    
    /**
     下面的函数是fishhook提供的函数：“重绑定符号表”函数；
     函数里面的第一个参数"struct rebinding rebindings[]"代表着存放rebinding结构体的数组；
     函数里面的第二个参数"size_t rebindings_nel"代表着它的第一个参数存放的数组的长度；
     */
    rebind_symbols(rebs, 1);
}

#pragma mark ————— 更改系统原生的NSLog方法 —————
//函数指针（保存系统的NSLog方法）
static void(*sys_nslog)(NSString * format,...);

//定义一个新的函数
void myNslog(NSString * format,...)  //"..."的意思是代表可扩展参数
{
    format = [format stringByAppendingString:@"勾上了！\n"];
    
    /**
     利用fishhook让在控制台打印的时候由原来的调用系统的"NSLog"方法变为了现在的调用自己写的方法；
     然后再调用原来的系统的"NSLog"方法，在控制台上面打印；
     因为"sys_nslog"函数指针保存了系统的"NSLog"方法，所以直接调用它就相当于调用了系统的"NSLog"方法了。
     */
    sys_nslog(format);
}

#pragma mark ————— 点击屏幕 —————
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    /**
     因为在"fishhook"方法中已经做了方法的交换，所以当系统调用原生的"NSLog"方法时就会执行新的函数"myNslog"。
     */
    NSLog(@"点击了屏幕！！");
}

@end
