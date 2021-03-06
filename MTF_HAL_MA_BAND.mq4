//+------------------------------------------------------------------+
//|                                                   MTF_HAL_MA.mq4 |
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
#property indicator_color1 clrLime
#property indicator_width1 1
#property indicator_type1 DRAW_LINE

//2
#property indicator_color2 clrLime
#property indicator_width2 1
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

extern int MinPeriod = 240; // ハル移動平均線の期間1
extern int MaxPeriod = 320; // ハル移動平均線の期間1
ENUM_MA_METHOD Method = MODE_LWMA;
extern ENUM_TIMEFRAMES TargetPeriod = PERIOD_H1; // MTF表示する時間軸
double pHMA[];
double pHMA2[];
double minHma[]; //バッファ配列
double maxHma[]; //バッファ配列
double up[];     //バッファ配列
double down[];   //バッファ配列

string ReminingTime_sname = "bars_remining_time";
extern bool RemainingTimeEnabled = False; // 確定までの時間を表示する
// extern int Corner = 0;
extern double LocationX = 1050; // 確定までの残り時間を表示する場所（X座標）
extern double LocationY = 20;   // 確定までの残り時間を表示する場所（Y座標）
extern int FontSize = 20;       // 確定までの残り時間を表示する文字サイズ
extern color FontColor = White; // 確定までの残り時間を表示する文字色

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
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

  string shortName = "HAL MTF";
  IndicatorShortName(shortName);
  //---
  return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
{
  ObjectDelete(ReminingTime_sname);
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
    int shift = iBarShift(NULL, TargetPeriod, time[i], false);
    up[i] = pHMA[i] = iMA(NULL, TargetPeriod, (MinPeriod / 2), 0, Method, PRICE_CLOSE, shift) * 2 - iMA(NULL, TargetPeriod, MinPeriod, 0, Method, PRICE_CLOSE, shift);
    down[i] = pHMA2[i] = iMA(NULL, TargetPeriod, (MaxPeriod / 2), 0, Method, PRICE_CLOSE, shift) * 2 - iMA(NULL, TargetPeriod, MaxPeriod, 0, Method, PRICE_CLOSE, shift);
  }
  for (int i = limit - 1; i >= 0 && !IsStopped(); i--)
  {
    minHma[i] = iMAOnArray(pHMA, 0, (int)MathFloor(MathSqrt(MinPeriod)), 0, Method, i);
    maxHma[i] = iMAOnArray(pHMA2, 0, (int)MathFloor(MathSqrt(MaxPeriod)), 0, Method, i);
    up[i] = minHma[i];
    down[i] = maxHma[i];
  }

  double g;
  int m, s, k, h;
  m = Time[0] + Period() * 60 - TimeCurrent();
  g = m / 60.0;
  s = m % 60;
  m = (m - m % 60) / 60;

  string text;

  if (Period() <= PERIOD_H1)
  {
    text = "残り " + m + " 分 " + s + " 秒";
  }
  else
  {
    if (m >= 60)
      h = m / 60;
    else
      h = 0;
    k = m - (h * 60);
    text = "残り " + h + " 時間 " + k + " 分 " + s + " 秒";
  }

  if (RemainingTimeEnabled)
  {
    ObjectCreate(ReminingTime_sname, OBJ_LABEL, 0, 0, 0);
    ObjectSetText(ReminingTime_sname, text, FontSize, "Terminal", FontColor);
    ObjectSet(ReminingTime_sname, OBJPROP_XDISTANCE, LocationX);
    ObjectSet(ReminingTime_sname, OBJPROP_YDISTANCE, LocationY);
    // ObjectSet(ReminingTime_sname, OBJPROP_CORNER, Corner);
  }

  //--- return value of prev_calculated for next call
  return (rates_total);
}
//+------------------------------------------------------------------+
