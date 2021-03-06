#property copyright "Copyright 2019, 崩れかけた家"
#property link "https://discordapp.com/invite/N9PMEym"
#property version "1.00"
#property strict

// インジケータウインドウ設定
#property indicator_chart_window

// インジケータ設定
#property indicator_buffers 16
#property indicator_color1 Red
#property indicator_color2 Blue
#property indicator_color3 Red

#property indicator_color4 Red
#property indicator_color5 Red
#property indicator_color6 Green
#property indicator_color7 Green
#property indicator_color8 clrWhite
#property indicator_color9 clrWhite

//3
#property indicator_type13 DRAW_HISTOGRAM
#property indicator_color13 clrRed
#property indicator_style13 STYLE_DOT
#property indicator_width13 1

//4
#property indicator_type14 DRAW_HISTOGRAM
#property indicator_color14 clrAqua
#property indicator_style14 STYLE_DOT
#property indicator_width14 1

//3
#property indicator_type15 DRAW_HISTOGRAM
#property indicator_color15 clrGray
#property indicator_style15 STYLE_DOT
#property indicator_width15 1

//4
#property indicator_type16 DRAW_HISTOGRAM
#property indicator_color16 clrGray
#property indicator_style16 STYLE_DOT
#property indicator_width16 1

// パラメータ
extern int shift_cloud = 0; // シフト

// ENUM
enum maMethod_List
{
   SMA = 0,  // 単純移動平均線
   EMA = 1,  // 指数移動平均線
   SMMA = 2, // 平滑移動平均線
   LWMA = 3  // 線形加重移動平均戦
};
enum timeFrame_List
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
enum appliedPrice_List
{
   CLOSE = 0,   // 終値
   OPEN = 1,    // 始値
   HIGH = 2,    // 高値
   LOW = 3,     // 安値
   MEDIAN = 4,  // 中央値
   TYPICAL = 5, // 代表値
   WEIGHTED = 6 // 加重終値
};

// MTF用
int mtf_timeframeId;
extern timeFrame_List mtf_timeframe = Current_timeFrame; // MTFで表示させる時間軸

// ケルトナーチャネル用
int kelt_mamethodId;
int kelt_appliedId;
extern int kelt_period = 20;                   // ケルトナーチャネル算出期間
extern maMethod_List kelt_mamethod = SMA;      // ケルトナーチャネル計算時に使う移動平均線計算方法
extern appliedPrice_List kelt_applied = CLOSE; // ケルトナーチャネル計算時に使う値段
extern double atr_times = 1.0;                 // ATRに何倍するか

// ボリンジャーバンド用
int bb_mamethodId;
int bb_appliedId;
extern int bb_period = 20;                   // ボリンジャーバンド算出期間
extern maMethod_List bb_mamethod = EMA;      // ボリンジャーバンド計算時に使う移動平均線計算方法
extern appliedPrice_List bb_applied = CLOSE; // ボリンジャーバンド計算時に使う値段
extern double sigma_times = 1.0;             // σに何倍するか

datetime b4time;
double b4ma = 0;

// 配列初期化
double ave_upper[], kelt_middle[], ave_middle[], ave_lower[], atr[], ma20[], up[], down[], up2[], down2[];
double ave_upper_up[], ave_lower_up[], ave_upper_down[], ave_lower_down[], ave_upper_range[], ave_lower_range[];

int OnInit()
{
   // インジゲーター表示設定
   // ave_upper band
   SetIndexBuffer(0, ave_upper);
   SetIndexStyle(0, DRAW_LINE);

   // kelt_middle band
   SetIndexBuffer(1, ave_middle);
   SetIndexStyle(1, DRAW_LINE, STYLE_DASHDOT);

   // ave_lower band
   SetIndexBuffer(2, ave_lower);
   SetIndexStyle(2, DRAW_LINE);

   SetIndexBuffer(9, atr);
   SetIndexBuffer(10, ma20);
   SetIndexBuffer(11, kelt_middle);

   SetIndexBuffer(5, ave_upper_up);
   SetIndexBuffer(6, ave_lower_up);
   SetIndexBuffer(3, ave_upper_down);
   SetIndexBuffer(4, ave_lower_down);
   SetIndexBuffer(7, ave_upper_range);
   SetIndexBuffer(8, ave_lower_range);

   SetIndexBuffer(12, up);
   SetIndexBuffer(13, down);
   SetIndexBuffer(14, up2);
   SetIndexBuffer(15, down2);

   kelt_mamethodId = kelt_mamethod;
   kelt_appliedId = kelt_applied;
   bb_mamethodId = bb_mamethod;
   bb_appliedId = bb_applied;
   mtf_timeframeId = mtf_timeframe;
   return (INIT_SUCCEEDED);
}

int OnCalculate(
    const int rates_total,
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
   bool isNewCandle = Time[0] != b4time && limit == 2;

   for (int i = limit - 1; i >= 0; i--)
   {
      int shift = iBarShift(NULL, mtf_timeframeId, time[i], false);

      // 20SMA算出
      double ma20_ = iMA(NULL, mtf_timeframeId, 20, 0, MODE_SMA, PRICE_CLOSE, shift);
      ma20[i] = ma20_;

      // ケルトナーチャネルミドルライン算出
      double kelt_middle_ = iMA(NULL, mtf_timeframeId, kelt_period, 0, kelt_mamethodId, kelt_appliedId, shift);
      kelt_middle[i] = kelt_middle_;
      // ボリンジャーバンドとケルトナーチャネルの平均値（ミドルライン）
      ave_middle[i] = (ma20[i] + kelt_middle[i]) / 2;
      double atr_ = iATR(NULL, mtf_timeframeId, kelt_period, shift);
      atr[i] = atr_;
      // ボリンジャーバンドとケルトナーチャネルの平均値（アッパーライン）
      double ave_upper_ = ((kelt_middle[i] + atr[i] * atr_times) + iBands(NULL, mtf_timeframeId, bb_period, sigma_times, shift_cloud, bb_appliedId, MODE_UPPER, shift)) / 2;
      ave_upper[i] = ave_upper_;
      // ボリンジャーバンドとケルトナーチャネルの平均値（ローワーライン）
      double ave_lower_ = ((kelt_middle[i] - atr[i] * atr_times) + iBands(NULL, mtf_timeframeId, bb_period, sigma_times, shift_cloud, bb_appliedId, MODE_LOWER, shift)) / 2;
      ave_lower[i] = ave_lower_;

      datetime startTime = iTime(NULL, mtf_timeframeId, shift);
      datetime endTime = 0;
      if (i > 0)
      {
         endTime = iTime(NULL, mtf_timeframeId, shift - 1);
      }
      else
      {
         endTime = startTime + PeriodSeconds(mtf_timeframeId);
      }

      // バンドウォーク判定
      bool isBandWalk = iBands(NULL, mtf_timeframeId, bb_period, 1, shift_cloud, bb_appliedId, MODE_UPPER, shift) > (kelt_middle[i] + atr[i] * atr_times);

      if (isBandWalk && b4ma < ma20_)
      {
         up[i] = ave_lower[i];
         down[i] = ave_upper[i];
      }
      else if (isBandWalk && b4ma > ma20_)
      {
         up[i] = ave_upper[i];
         down[i] = ave_lower[i];
      }
      else
      {
         up2[i] = ave_lower[i];
         down2[i] = ave_upper[i];
      }

      b4time = Time[0];
      b4ma = ma20[i];
   }
   return (rates_total);
}