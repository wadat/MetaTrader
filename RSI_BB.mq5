//+------------------------------------------------------------------+
//|                                                       RSI_BB.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window

#property indicator_buffers 4
#property indicator_plots 1

#property indicator_type1 DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_width1 2

#property indicator_type2 DRAW_LINE
#property indicator_color2 clrGreen
#property indicator_width2 2

#property indicator_type3 DRAW_LINE
#property indicator_color3 clrGreen

#property indicator_type4 DRAW_LINE
#property indicator_color4 clrGreen

#property indicator_level1 30.0
#property indicator_level2 50.0
#property indicator_level3 70.0

#property indicator_levelcolor clrDeepPink

input int RSI_Period = 14;
input int BB_Period = 20;
input int BB_Shift = 0;
input double BB_Deviation = 2.0;

input ENUM_APPLIED_PRICE inpAppliedPrice = PRICE_CLOSE; // 適用価格

double RSI_Buffer[];
double BBML_Buffer[];
double BBTL_Buffer[];
double BBBL_Buffer[];

int hRSI;
int hBB;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   if( (RSI_Period < 1) || (BB_Period < 0))
   {
      Print("ERROR: Invalid inpMaPeriod value");
      return(INIT_FAILED);
   }
//--- indicator buffers mapping
   SetIndexBuffer(0,RSI_Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,BBML_Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,BBTL_Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,BBBL_Buffer,INDICATOR_DATA);
   
   IndicatorSetString(INDICATOR_SHORTNAME,"RSI&BB("+string(RSI_Period)+";"+string(BB_Period)+")");
   PlotIndexSetString(0,PLOT_LABEL,"RSI("+string(RSI_Period)+")");
   PlotIndexSetString(1,PLOT_LABEL,"BB Middle("+string(BB_Period)+")");
   PlotIndexSetString(2,PLOT_LABEL,"BB Top("+string(BB_Period)+";"+string(BB_Deviation)+")");
   PlotIndexSetString(3,PLOT_LABEL,"BB Bottom("+string(BB_Period)+";"+string(BB_Deviation)+")");
   IndicatorSetInteger(INDICATOR_DIGITS,2);

//--- get MA handles
   hRSI = iRSI(NULL,0,RSI_Period,inpAppliedPrice);
   hBB = iBands(NULL,0,BB_Period,BB_Shift,BB_Deviation,hRSI);
   if( (hRSI==INVALID_HANDLE) || (hBB==INVALID_HANDLE) )
   {
      Print("ERROR: INVALID_HANDLE");
      return(INIT_FAILED);
   }

//---
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int32_t rates_total,
                const int32_t prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int32_t &spread[])
{
//---
   if((BarsCalculated(hRSI) < rates_total) && (BarsCalculated(hBB) < rates_total))
      return(0);
   
   int to_copy;
   to_copy = rates_total - prev_calculated;
   if(to_copy==0)
      to_copy++;
   
   if(CopyBuffer(hRSI,0,0,to_copy,RSI_Buffer) <= 0)
      return(0);
   if(CopyBuffer(hBB,0,0,to_copy,BBML_Buffer) <= 0)
      return(0);
   if(CopyBuffer(hBB,1,0,to_copy,BBTL_Buffer) <= 0)
      return(0);
   if(CopyBuffer(hBB,2,0,to_copy,BBBL_Buffer) <= 0)
      return(0);

//--- return value of prev_calculated for next call
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(hRSI);
   IndicatorRelease(hBB);
}
//+------------------------------------------------------------------+
