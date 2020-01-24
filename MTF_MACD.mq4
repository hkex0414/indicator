//+------------------------------------------------------------------+
//|                                                     MTF_MACD.mq4 |
//|                                      Copyright 2020, 崩れかけた家 |
//|                            https://discordapp.com/invite/N9PMEym |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, 崩れかけた家"
#property link "https://discordapp.com/invite/N9PMEym"
#property version "1.00"
#property strict

//-----インジゲーター設定------
// 表示場所
// #property indicator_chart_window
#property indicator_buffers 4
#property indicator_separate_window

#property indicator_color1 Aqua
#property indicator_width1 1
#property indicator_type1 DRAW_NONE
#property indicator_style1 STYLE_SOLID

#property indicator_color2 Red
#property indicator_width2 1
#property indicator_type2 DRAW_NONE
#property indicator_style2 STYLE_SOLID

#property indicator_color3 OrangeRed

#property indicator_color4 BlueViolet
//---------------------------

//--------ENUM定義-----------
// Pascal方式
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
//---------------------------

//------パラメーター定義------
// Pascal方式
// MTF用
TimeFrameList MtfTimeFrame = Current_timeFrame; // MTFで表示させる時間軸
extern int FastEmaPeriod = 12;                  // 短期EMA期間
extern int SlowEmaPeriod = 26;                  // 長期EMA期間
extern int SignalPeriod = 9;                    // MACD SMA

extern AppliedPriceList MaAppliedPrice = CLOSE; // 適用先
//---------------------------

//-------変数・定数定義-------
// Camel方式
// アラート重複排除用
datetime b4Time;
int mtfTimeFrameId;
int maAppliedPriceId;
//---------------------------

//----------配列定義---------
// Camel方式
double macd[];
double signal[];
double up[];
double down[];
//---------------------------

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0, macd);
   SetIndexBuffer(1, signal);
   SetIndexBuffer(2, up);
   SetIndexStyle(2, DRAW_ARROW, STYLE_SOLID, 0.1);
   SetIndexArrow(2, 108);
   SetIndexBuffer(3, down);
   SetIndexStyle(3, DRAW_ARROW, STYLE_SOLID, 0.1);
   SetIndexArrow(3, 108);
   mtfTimeFrameId = MtfTimeFrame;
   maAppliedPriceId = MaAppliedPrice;
   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}
//+------------------------------------------------------------------+
//| Custom indicator start function                                  |
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
   // ループ上限
   int limit = Bars - IndicatorCounted();
   // 足が更新されたかの判定
   bool isNewCandle = Time[0] != b4Time && limit == 2;

   for (int i = limit - 1; i >= 0; i--)
   {
      //インジ計算処理
      int shift = iBarShift(NULL, mtfTimeFrameId, time[i], false);
      double fastMa = iMA(NULL, mtfTimeFrameId, FastEmaPeriod, 0, MODE_EMA, maAppliedPriceId, shift);
      double slowMa = iMA(NULL, mtfTimeFrameId, SlowEmaPeriod, 0, MODE_EMA, maAppliedPriceId, shift);
      // double fastMa = iMA(NULL, 0, FastEmaPeriod, 0, MODE_EMA, maAppliedPriceId, i);
      // double slowMa = iMA(NULL, 0, SlowEmaPeriod, 0, MODE_EMA, maAppliedPriceId, i);
      macd[i] = fastMa - slowMa;

      if (macd[i] >= 0)
      {
         up[i] = macd[i];
      }
      else if (macd[i] < 0)
      {
         down[i] = macd[i];
      }
      // macd[i] = NormalizeDouble(macd[i], MarketInfo(Symbol(), MODE_DIGITS) + 1);
   }
   // for (int i = limit - 1; i >= 0; i--)
   // {
   //    //インジ計算処理
   //    signal[i] = iMAOnArray(macd, 0, SignalPeriod, 0, MODE_EMA, i);
   //    // signal[i] = NormalizeDouble(signal[i], MarketInfo(Symbol(), MODE_DIGITS) + 1);
   // }
   // for (int i = limit - 1; i >= 0; i--)
   // {
   //    //インジ計算処理
   //    double diffarence = macd[i] - signal[i];
   //    if (diffarence >= 0)
   //    {
   //       up[i] = diffarence;
   //       // up[i] = NormalizeDouble(diffarence, MarketInfo(Symbol(), MODE_DIGITS) + 1);
   //    }
   //    else if (diffarence < 0)
   //    {
   //       down[i] = diffarence;
   //       // down[i] = NormalizeDouble(diffarence, MarketInfo(Symbol(), MODE_DIGITS) + 1);
   //    }
   // }
   return (rates_total);
}
