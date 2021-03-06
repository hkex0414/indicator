//+------------------------------------------------------------------+
//|                                                       MTF_MA.mq4 |
//|                                       Copyright 2019, 崩れかけた家 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, 崩れかけた家"
#property link "https://discordapp.com/invite/N9PMEym"
#property version "1.00"
#property strict

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots 4

//1
#property indicator_color1 clrAqua
#property indicator_width1 3
#property indicator_type1 DRAW_LINE

//2
#property indicator_color2 clrAqua
#property indicator_width2 3
#property indicator_type2 DRAW_LINE

//3
#property indicator_type3 DRAW_HISTOGRAM
#property indicator_color3 clrRed
#property indicator_style3 STYLE_DOT
#property indicator_width3 1

//4
#property indicator_type4 DRAW_HISTOGRAM
#property indicator_color4 clrAqua
#property indicator_style4 STYLE_DOT
#property indicator_width4 1

// MA算出方式
enum TaMethodList
{
  SMA = 0,  // 単純移動平均線
  EMA = 1,  // 指数移動平均線
  SMMA = 2, // 平滑移動平均線
  LWMA = 3  // 線形加重移動平均戦
};
// チャート時間軸
enum TimeFrameList
{
  Current_timeFrame = 0, // 現在の時間足
  M1 = 1,                // 1分足
  M5 = 5,                // 5分足
  M15 = 15,              // 15分足
  M30 = 30,              // 30分足
  H1 = 60,               // 1時間足
  H4 = 240,              // 4時間足
  D1 = 1440,             // 日足
  W1 = 10080,            //週足
  MN = 43200             // 月足
};
// 価格データ
enum AppliedPriceList
{
  CLOSE = 0,   // 終値
  OPEN = 1,    // 始値
  HIGH = 2,    // 高値
  LOW = 3,     // 安値
  MEDIAN = 4,  // 中央値
  TYPICAL = 5, // 代表値
  WEIGHTED = 6 // 加重終値
};

extern int MinPeriod = 3;                              // 移動平均線の期間1
extern int MaxPeriod = 15;                             // 移動平均線の期間1
extern TaMethodList Method = EMA;                      // MAの算出方式
extern TimeFrameList TargetPeriod = Current_timeFrame; // MTF表示する時間軸
extern AppliedPriceList AppliedPrice = CLOSE;          // MA算出の価格データ
double pHMA[];
double pHMA2[];
double minHma[]; //バッファ配列
double maxHma[]; //バッファ配列
double up[];     //バッファ配列
double down[];   //バッファ配列
int MethodId;
int TargetPeriodId;
int AppliedPriceId;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
  MethodId = Method;
  TargetPeriodId = TargetPeriod;
  AppliedPriceId = AppliedPrice;
  ArraySetAsSeries(pHMA, true);
  ArraySetAsSeries(pHMA2, true);

  ArrayResize(pHMA, Bars);
  ArrayResize(pHMA2, Bars);

  ArrayInitialize(pHMA, 0);
  ArrayInitialize(pHMA2, 0);

  //--- indicator buffers mapping
  SetIndexBuffer(0, minHma);
  SetIndexBuffer(1, maxHma);
  SetIndexBuffer(2, up);
  SetIndexBuffer(3, down);

  int Period = (int)MathMax(MinPeriod, MaxPeriod);
  SetIndexDrawBegin(0, Period);
  SetIndexDrawBegin(1, Period);
  SetIndexDrawBegin(2, Period);
  SetIndexDrawBegin(3, Period);

  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
  return (0);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
  //---
  int limit = Bars - IndicatorCounted();

  for (int i = limit - 1; i >= 0 && !IsStopped(); i--)
  {

    int shift = iBarShift(NULL, TargetPeriodId, time[i], false);
    up[i] = pHMA[i] = minHma[i] = iMA(NULL, TargetPeriodId, MinPeriod, 0, MethodId, AppliedPriceId, shift);
    down[i] = pHMA2[i] = maxHma[i] = iMA(NULL, TargetPeriod, MaxPeriod, 0, MethodId, AppliedPriceId, shift);
  }

  //--- return value of prev_calculated for next call
  return (rates_total);
}
//+------------------------------------------------------------------+
