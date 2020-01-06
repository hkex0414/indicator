//+------------------------------------------------------------------+
//|                                                   settai-rsi.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, K.mori"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window

#property  indicator_buffers 3

#property  indicator_width1    1
#property  indicator_type1     DRAW_LINE
#property  indicator_style1    STYLE_SOLID
#property  indicator_color1    clrGreen

#property  indicator_width2    1
#property  indicator_type2     DRAW_LINE
#property  indicator_style2    STYLE_SOLID
#property  indicator_color2    clrGreen

#property  indicator_width3    2
#property  indicator_type3     DRAW_LINE
#property  indicator_style3    STYLE_SOLID
#property  indicator_color3    clrPink

// レベルライン設定
#property indicator_level1	   0
#property indicator_levelcolor clrGray
#property indicator_levelwidth   1
#property indicator_levelstyle STYLE_DOT

// パラメーター
extern int RsiPeriod = 14; //RSI算出期間
extern bool PushNotify = true; // Push通知（要MetaQuotesID登録）

// 配列初期化

double settaiLine[];
double settaiLineMa[];
double rsiArray[];
double rsiMaArray[];
double Over_Zero[];
double Down_Zero[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
      SetIndexBuffer(0, rsiMaArray);
      SetIndexBuffer(1, rsiArray);
      SetIndexBuffer(2, settaiLine);
//---
   return(INIT_SUCCEEDED);
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

    for(int i = limit - 1; i >= 0; i --)
    {
      rsiArray[i] = iRSI(NULL, 0, RsiPeriod, PRICE_CLOSE, i);
    }
    for(int i = limit - 1; i >= 0; i --)
    {
      rsiMaArray[i] = iMAOnArray(rsiArray, 0, 20, 0, 0, i);
      settaiLine[i] = rsiArray[i] - rsiMaArray[i];
    }
    // for(int i = limit - 1; i >= 0; i --)
    // {
    //   settaiLine[i] = rsiArray[i] - rsiMaArray[i];
    // }
//--- return value of prev_calculated for next call
    return(rates_total);
  }
//+------------------------------------------------------------------+
