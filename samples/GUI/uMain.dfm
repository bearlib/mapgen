object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 520
  ClientWidth = 737
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 113
    Width = 472
    Height = 407
    Align = alClient
    ExplicitLeft = -6
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 737
    Height = 113
    Align = alTop
    TabOrder = 0
    object Button1: TButton
      Left = 8
      Top = 50
      Width = 75
      Height = 25
      Caption = 'Init'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 89
      Top = 50
      Width = 96
      Height = 25
      Caption = 'Generate Rooms'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 191
      Top = 50
      Width = 90
      Height = 25
      Caption = 'OffsetRooms'
      TabOrder = 2
      OnClick = Button3Click
    end
    object Button4: TButton
      Left = 287
      Top = 50
      Width = 96
      Height = 25
      Caption = 'PickMainRooms'
      TabOrder = 3
      OnClick = Button4Click
    end
    object Button5: TButton
      Left = 8
      Top = 82
      Width = 145
      Height = 25
      Caption = 'DelaunayTriangulation'
      TabOrder = 4
      OnClick = Button5Click
    end
    object Button6: TButton
      Left = 159
      Top = 82
      Width = 122
      Height = 25
      Caption = 'MinimalTree'
      TabOrder = 5
      OnClick = Button6Click
    end
    object Button7: TButton
      Left = 287
      Top = 82
      Width = 96
      Height = 25
      Caption = 'DrawHallways'
      TabOrder = 6
      OnClick = Button7Click
    end
    object leMapX: TLabeledEdit
      Left = 8
      Top = 23
      Width = 121
      Height = 21
      EditLabel.Width = 26
      EditLabel.Height = 13
      EditLabel.Caption = 'MapX'
      TabOrder = 7
      Text = '80'
    end
    object leMapY: TLabeledEdit
      Left = 135
      Top = 23
      Width = 121
      Height = 21
      EditLabel.Width = 26
      EditLabel.Height = 13
      EditLabel.Caption = 'MapY'
      TabOrder = 8
      Text = '40'
    end
    object leNRooms: TLabeledEdit
      Left = 262
      Top = 23
      Width = 121
      Height = 21
      EditLabel.Width = 39
      EditLabel.Height = 13
      EditLabel.Caption = 'NRooms'
      TabOrder = 9
      Text = '150'
    end
    object Button10: TButton
      Left = 440
      Top = 8
      Width = 129
      Height = 41
      Caption = 'DO ALL'
      TabOrder = 10
      OnClick = Button10Click
    end
    object cbCells: TCheckBox
      Left = 584
      Top = 16
      Width = 97
      Height = 17
      Caption = 'Cells'
      Checked = True
      State = cbChecked
      TabOrder = 11
      OnClick = cbRoomsClick
    end
    object cbRooms: TCheckBox
      Left = 584
      Top = 40
      Width = 97
      Height = 17
      Caption = 'Rooms'
      Checked = True
      State = cbChecked
      TabOrder = 12
      OnClick = cbRoomsClick
    end
    object cbLinks: TCheckBox
      Left = 584
      Top = 64
      Width = 97
      Height = 17
      Caption = 'Links'
      Checked = True
      State = cbChecked
      TabOrder = 13
      OnClick = cbRoomsClick
    end
    object edSeed: TEdit
      Left = 440
      Top = 83
      Width = 121
      Height = 21
      TabOrder = 14
      Text = 'edSeed'
    end
    object CheckBox1: TCheckBox
      Left = 440
      Top = 60
      Width = 97
      Height = 17
      Caption = 'seed'
      TabOrder = 15
    end
  end
  object vle1: TValueListEditor
    Left = 472
    Top = 113
    Width = 265
    Height = 407
    Align = alRight
    Strings.Strings = (
      'RoomMinSize=3'
      'RoomMaxSize=11'
      'MaxSizeRatio=1.8'
      'InitialRadius=0.1'
      'RoomThreshold=6'
      'AdditionalLinks=0.15')
    TabOrder = 1
    ColWidths = (
      150
      109)
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 100
    OnTimer = Button10Click
    Left = 232
    Top = 192
  end
end
