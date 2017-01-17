object frMain: TfrMain
  Left = 343
  Top = 77
  Caption = 'frMain'
  ClientHeight = 544
  ClientWidth = 514
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesigned
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object chbHookRegistered: TCheckBox
    Left = 0
    Top = 0
    Width = 514
    Height = 17
    Align = alTop
    Caption = 'Hotkey registered'
    TabOrder = 0
    OnClick = chbHookRegisteredClick
  end
  object lbHotkeys: TListBox
    Left = 0
    Top = 17
    Width = 514
    Height = 88
    Align = alTop
    ItemHeight = 13
    TabOrder = 1
  end
  object mInfo: TMemo
    Left = 0
    Top = 105
    Width = 514
    Height = 439
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    Lines.Strings = (
      'mInfo')
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 2
  end
end
