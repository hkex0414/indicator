#property version "1.00"
#property indicator_levelcolor clrGray
#property indicator_levelwidth 1
#property strict

// インジケータウインドウ設定
#property indicator_separate_window

// インジケータ設定
#property indicator_buffers 5

#property indicator_width1 2
#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_color1 clrRed

#property indicator_width2 2
#property indicator_type2 DRAW_LINE
#property indicator_style2 STYLE_SOLID
#property indicator_color2 clrBlue

#property indicator_width3 2
#property indicator_type3 DRAW_LINE
#property indicator_style3 STYLE_SOLID
#property indicator_color3 clrGreen

// レベルライン設定
#property indicator_level1 0
#property indicator_levelcolor clrGray
#property indicator_levelwidth 1
#property indicator_levelstyle STYLE_DOT

#property indicator_level2 - 70
#property indicator_levelstyle STYLE_DOT

#property indicator_level3 70
#property indicator_levelcolor clrGray
#property indicator_levelwidth 1
#property indicator_levelstyle STYLE_DOT

//UPDOWN サインオブジェクト名
const string OBJECT_NAME = "RCI 3linez";

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
timeFrame_List mtf_timeframe = Current_timeFrame; // MTFで表示させる時間軸

// パラメーター（RCI期間）
extern int short_period = 9;   // 短期
extern int middle_period = 36; // 中期
extern int long_period = 52;   // 長期

// パラメーター（通知設定）
extern bool Push_Notification_Enabled = true;  // Push通知（要MetaQuotesID登録）
extern bool Mail_Notification_Enabled = false; // メール通知（要メール通知設定）

datetime b4time;
static int Bar[2];

// 配列初期化
double short_[], middle_[], long_[];

int OnInit()
{
    // インジゲーター表示設定
    SetIndexBuffer(0, short_);
    SetIndexBuffer(1, middle_);
    SetIndexBuffer(2, long_);

    // インジゲーターウィンドウ上限値・下限値
    IndicatorSetDouble(INDICATOR_MINIMUM, -100);
    IndicatorSetDouble(INDICATOR_MAXIMUM, 100);

    mtf_timeframeId = mtf_timeframe;

    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
    ObjectsDeleteAll(ChartID());
}

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

    for (int i = limit - 1; i >= 0; i--)
    {

        int shift = iBarShift(NULL, mtf_timeframeId, time[i], false);

        // 足が更新されたかの確認
        Bar[1] = Bar[0];
        Bar[0] = iBars(Symbol(), mtf_timeframeId);
        bool isNewCandle = Bar[1] != Bar[0];

        // RCI短期算出
        double short_temp = iRCI(NULL, mtf_timeframeId, short_period, shift);
        short_[i] = short_temp;
        // RCI中期算出
        double middle_temp = iRCI(NULL, mtf_timeframeId, middle_period, shift);
        middle_[i] = middle_temp;
        // RCI長期算出
        double long_temp = iRCI(NULL, mtf_timeframeId, long_period, shift);
        long_[i] = long_temp;

        // 中長期70以上または-70以下
        bool is70over = (middle_temp >= 70 && long_temp >= 70) || (middle_temp <= -70 && long_temp <= -70);
        // GC判定
        bool isGC = (iRCI(NULL, mtf_timeframeId, middle_period, shift) > iRCI(NULL, mtf_timeframeId, long_period, shift) && iRCI(NULL, mtf_timeframeId, middle_period, shift + 1) <= iRCI(NULL, mtf_timeframeId, long_period, shift + 2)) && (middle_temp <= -70 && long_temp <= -70);
        // DC判定
        bool isDC = (iRCI(NULL, mtf_timeframeId, middle_period, shift) < iRCI(NULL, mtf_timeframeId, long_period, shift) && iRCI(NULL, mtf_timeframeId, middle_period, shift + 1) >= iRCI(NULL, mtf_timeframeId, long_period, shift + 2)) && (middle_temp >= 70 && long_temp >= 70);
        // 通知状態確認
        bool Notify = Push_Notification_Enabled || Mail_Notification_Enabled;

        if (isGC && Notify && isNewCandle)
        {
            if (Push_Notification_Enabled)
            {
                PushNotification(Symbol() + " " + Period() + " " + "GC");
            }
            if (Mail_Notification_Enabled)
            {
                MailNotification("RCI", Symbol() + " " + Period() + " " + "GC");
            }
            b4time = Time[0];
        }
        if (isDC && Notify && isNewCandle)
        {
            if (Push_Notification_Enabled)
            {
                PushNotification(Symbol() + " " + Period() + " " + "DC");
            }
            if (Mail_Notification_Enabled)
            {
                MailNotification("RCI", Symbol() + " " + Period() + " " + "DC");
            }
            b4time = Time[0];
        }
    }
    return (rates_total);
}

double iRCI(const string symbol, int timeframe, int period, int index)
{
    int rank;
    double d = 0;
    double close_arr[];
    ArrayResize(close_arr, period);

    for (int i = 0; i < period; i++)
    {
        close_arr[i] = iClose(symbol, timeframe, index + i);
    }

    ArraySort(close_arr, WHOLE_ARRAY, 0, MODE_DESCEND);

    for (int j = 0; j < period; j++)
    {
        rank = ArrayBsearch(close_arr,
                            iClose(symbol, timeframe, index + j),
                            WHOLE_ARRAY,
                            0,
                            MODE_DESCEND);
        d += MathPow(j - rank, 2);
    }

    return ((1 - 6 * d / (period * (period * period - 1))) * 100);
}

// Push通知用関数
bool PushNotification(string msg)
{
    Alert(msg);
    return SendNotification(msg);
}

// メール通知用関数
bool MailNotification(string subject, string body)
{
    return SendMail(subject, body);
}

//　売買矢印オブジェクト生成関数
bool CreateArrawObject(
    ENUM_OBJECT objectType, // オブジェクトの種類(OBJ_ARROW_BUY/OBJ_ARROW_SELL)
    datetime time,          // 表示時間（横軸）
    double price)           // 表示時間（縦軸）
{
    // オブジェクトを作成する。
    long chartId = ChartID();

    ObjectDelete(chartId, OBJECT_NAME);

    if (!ObjectCreate(chartId, OBJECT_NAME, OBJ_ARROW, 0, time, price))
    {
        Alert("aaa");
        return false;
    }
    ObjectSetInteger(chartId, OBJECT_NAME, OBJPROP_HIDDEN, true);
    ObjectSetInteger(chartId, OBJECT_NAME, OBJPROP_COLOR, objectType == OBJ_ARROW_BUY ? C '200,200,255' : C '255,128,128');
    ObjectSetInteger(chartId, OBJECT_NAME, OBJPROP_ARROWCODE, objectType == OBJ_ARROW_BUY ? 233 : 234);

    return true;
}