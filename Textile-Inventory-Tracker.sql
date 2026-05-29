CREATE TABLE tblKategoriler (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Ad NVARCHAR(50) NOT NULL
);
CREATE TABLE tblRenkler (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Ad NVARCHAR(50) NOT NULL,
    HexKod NVARCHAR(7) NULL
);
CREATE TABLE tblBedenler (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Ad NVARCHAR(10) NOT NULL,
    Sira INT NOT NULL -- S sorting like 1, 2, 3
);
CREATE TABLE tblRoller (
    ID INT PRIMARY KEY IDENTITY(1,1),
    RolAdi NVARCHAR(50) NOT NULL
);
CREATE TABLE tblLokasyonlar (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Ad NVARCHAR(100) NOT NULL,
    Tur NVARCHAR(20) NOT NULL, -- 'Magaza', 'Depo'
    Adres NVARCHAR(250) NULL,
    Mesafe INT DEFAULT 0 -- For 'Nearest Store' logic
);
CREATE TABLE tblTedarikciler (
    ID INT PRIMARY KEY IDENTITY(1,1),
    FirmaAdi NVARCHAR(100) NOT NULL,
    YetkiliKisi NVARCHAR(100) NULL,
    Telefon NVARCHAR(20) NULL,
    Adres NVARCHAR(250) NULL
);
CREATE TABLE tblMusteriler (
    ID INT PRIMARY KEY IDENTITY(1,1),
    AdSoyad NVARCHAR(100) NOT NULL,
    Telefon NVARCHAR(20) NULL,
    Eposta NVARCHAR(100) NULL,
    Adres NVARCHAR(250) NULL
);
CREATE TABLE tblSezonlar (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Ad NVARCHAR(50) NOT NULL, -- Yaz 2025
    BaslangicTarihi DATE NULL,
    BitisTarihi DATE NULL,
    AktifMi BIT DEFAULT 1
);
-- 3. PRODUCT & INVENTORY TABLES
CREATE TABLE tblUrunler (
    ID INT PRIMARY KEY IDENTITY(1,1),
    UrunKodu NVARCHAR(50) NOT NULL, -- V1921...
    Ad NVARCHAR(100) NOT NULL,
    KategoriID INT FOREIGN KEY REFERENCES tblKategoriler(ID),
    SezonID INT FOREIGN KEY REFERENCES tblSezonlar(ID),
    ResimYolu NVARCHAR(250) NULL,
    Aciklama NVARCHAR(MAX) NULL
);
CREATE TABLE tblStokKartlari (
    ID INT PRIMARY KEY IDENTITY(1,1),
    UrunID INT FOREIGN KEY REFERENCES tblUrunler(ID),
    RenkID INT FOREIGN KEY REFERENCES tblRenkler(ID),
    BedenID INT FOREIGN KEY REFERENCES tblBedenler(ID),
    Barkod NVARCHAR(50) NOT NULL UNIQUE,
    KritikStokSeviyesi INT DEFAULT 10
);
CREATE TABLE tblStokDurum (
    ID INT PRIMARY KEY IDENTITY(1,1),
    StokKartID INT FOREIGN KEY REFERENCES tblStokKartlari(ID),
    LokasyonID INT FOREIGN KEY REFERENCES tblLokasyonlar(ID),
    Miktar INT DEFAULT 0,
    Raf NVARCHAR(20) NULL -- Raf No: A-12
);
-- 4. PERSONNEL & SECURITY
CREATE TABLE tblPersoneller (
    ID INT PRIMARY KEY IDENTITY(1,1),
    PersonelNo NVARCHAR(20) NOT NULL UNIQUE,
    SicilNo NVARCHAR(50) NULL,
    AdSoyad NVARCHAR(100) NOT NULL,
    Sifre NVARCHAR(50) NOT NULL, -- Plaintext as requested (TextBox2)
    RolID INT FOREIGN KEY REFERENCES tblRoller(ID),
    LokasyonID INT FOREIGN KEY REFERENCES tblLokasyonlar(ID),
    ResimYolu NVARCHAR(250) NULL,
    Durum BIT DEFAULT 1, -- 1: Active, 0: Passive
    IseGirisTarihi DATETIME DEFAULT GETDATE()
);
CREATE TABLE tblYetkiler (
    ID INT PRIMARY KEY IDENTITY(1,1),
    YetkiAdi NVARCHAR(50) NOT NULL,
    Kod NVARCHAR(50) NOT NULL -- STOCK_ENTRY, REPORT_VIEW
);
CREATE TABLE tblPersonelYetkileri (
    ID INT PRIMARY KEY IDENTITY(1,1),
    PersonelID INT FOREIGN KEY REFERENCES tblPersoneller(ID),
    YetkiID INT FOREIGN KEY REFERENCES tblYetkiler(ID),
    GeciciMi BIT DEFAULT 0,
    BaslangicTarihi DATETIME NULL,
    BitisTarihi DATETIME NULL
);
CREATE TABLE tblGirisLoglari (
    ID INT PRIMARY KEY IDENTITY(1,1),
    PersonelID INT FOREIGN KEY REFERENCES tblPersoneller(ID),
    GirisZamani DATETIME DEFAULT GETDATE()
);
-- 5. TRANSACTIONS & LOGGING
CREATE TABLE tblStokHareketleri (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Tarih DATETIME DEFAULT GETDATE(),
    StokKartID INT FOREIGN KEY REFERENCES tblStokKartlari(ID),
    IslemTuru NVARCHAR(20) NOT NULL, -- Giris, Cikis, Satis, Sayim, Iade
    IslemSebebi NVARCHAR(50) NULL, -- Sayim Fazlasi, Hasarli
    Miktar INT NOT NULL,
    Raf NVARCHAR(20) NULL,
    CikisLokasyonID INT FOREIGN KEY REFERENCES tblLokasyonlar(ID), -- Gidis Yeri (Source for exit)
    GirisLokasyonID INT FOREIGN KEY REFERENCES tblLokasyonlar(ID), -- Gelis Yeri (Dest for entry)
    TedarikciID INT FOREIGN KEY REFERENCES tblTedarikciler(ID),
    PersonelID INT FOREIGN KEY REFERENCES tblPersoneller(ID),
    Aciklama NVARCHAR(MAX) NULL
);
CREATE TABLE tblHasarKayitlari (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Tarih DATETIME DEFAULT GETDATE(),
    StokKartID INT FOREIGN KEY REFERENCES tblStokKartlari(ID),
    Adet INT NOT NULL,
    HasarTuru NVARCHAR(50) NULL,
    BildirimYeri NVARCHAR(50) NULL, -- Depo, Mudur
    Durum NVARCHAR(20) DEFAULT 'Beklemede',
    Aciklama NVARCHAR(250) NULL,
    PersonelID INT FOREIGN KEY REFERENCES tblPersoneller(ID)
);
CREATE TABLE tblRezervasyonlar (
    ID INT PRIMARY KEY IDENTITY(1,1),
    MusteriID INT FOREIGN KEY REFERENCES tblMusteriler(ID),
    StokKartID INT FOREIGN KEY REFERENCES tblStokKartlari(ID),
    Adet INT NOT NULL,
    BaslangicTarihi DATETIME DEFAULT GETDATE(),
    BitisTarihi DATETIME NULL,
    Durum NVARCHAR(20) DEFAULT 'Aktif', -- Aktif, Tamamlandi, Iptal
    Aciklama NVARCHAR(250) NULL,
    PersonelID INT FOREIGN KEY REFERENCES tblPersoneller(ID)
);
-- 6. SALES & SHIPMENTS
CREATE TABLE tblSatislar (
    ID INT PRIMARY KEY IDENTITY(1,1),
    Tarih DATETIME DEFAULT GETDATE(),
    MusteriID INT FOREIGN KEY REFERENCES tblMusteriler(ID),
    PersonelID INT FOREIGN KEY REFERENCES tblPersoneller(ID),
    ToplamTutar DECIMAL(18,2) DEFAULT 0,
    OdemeYontemi NVARCHAR(50) NULL
);
CREATE TABLE tblSatisDetay (
    ID INT PRIMARY KEY IDENTITY(1,1),
    SatisID INT FOREIGN KEY REFERENCES tblSatislar(ID),
    StokKartID INT FOREIGN KEY REFERENCES tblStokKartlari(ID),
    Adet INT NOT NULL,
    BirimFiyat DECIMAL(18,2) NOT NULL,
    ToplamFiyat DECIMAL(18,2) NOT NULL
);
CREATE TABLE tblSevkiyatlar (
    ID INT PRIMARY KEY IDENTITY(1,1),
    SevkiyatNo NVARCHAR(50) NOT NULL UNIQUE,
    CikisLokasyonID INT FOREIGN KEY REFERENCES tblLokasyonlar(ID),
    GirisLokasyonID INT FOREIGN KEY REFERENCES tblLokasyonlar(ID),
    Tarih DATETIME DEFAULT GETDATE(),
    Durum NVARCHAR(20) DEFAULT 'Beklemede',
    OlusturanPersonelID INT FOREIGN KEY REFERENCES tblPersoneller(ID),
    Aciklama NVARCHAR(MAX) NULL
);
CREATE TABLE tblSevkiyatDetay (
    ID INT PRIMARY KEY IDENTITY(1,1),
    SevkiyatID INT FOREIGN KEY REFERENCES tblSevkiyatlar(ID),
    StokKartID INT FOREIGN KEY REFERENCES tblStokKartlari(ID),
    Adet INT NOT NULL,
    Durum NVARCHAR(20) NULL
);
-- 7. DUMMY DATA INSERTION (Basic Setup)
-- Kategoriler
INSERT INTO tblKategoriler (Ad) VALUES ('Pantolon'), ('T-Shirt'), ('Kazak'), ('Ceket');
-- Renkler
INSERT INTO tblRenkler (Ad, HexKod) VALUES ('Siyah', '#000000'), ('Beyaz', '#FFFFFF'), ('Mavi', '#0000FF'), ('Kýrmýzý', '#FF0000'),('Yeþil', '#008000');
-- Bedenler
INSERT INTO tblBedenler (Ad, Sira) VALUES ('S', 1), ('M', 2), ('L', 3), ('XL', 4);
-- Roller
INSERT INTO tblRoller (RolAdi) VALUES ('Müdür'), ('Depo Sorumlusu'), ('Maðaza Personeli');
-- Lokasyonlar
INSERT INTO tblLokasyonlar (Ad, Tur, Mesafe) VALUES ('Merkez Depo', 'Depo', 0), ('Kadýköy Þubesi', 'Magaza', 10), ('Beþiktaþ Þubesi', 'Magaza', 15);
-- Personeller (Umut MUTLU demo user)
-- Passwords are plaintext as requested. In real app, use hashing!
INSERT INTO tblPersoneller (PersonelNo, AdSoyad, Sifre, RolID, LokasyonID, Durum) 
VALUES 
('1001', 'Umut MUTLU', '12345', 2, 1, 1), -- Depo Sorumlusu
('2001', 'Ayþe YILMAZ', '12345', 3, 2, 1), -- Maðaza Personeli
('9001', 'Cisem ÇAKIR', 'admin', 1, 1, 1); -- Müdür
-- Sezonlar
INSERT INTO tblSezonlar (Ad, BaslangicTarihi, BitisTarihi) VALUES ('Yaz 2025', '2025-06-01', '2025-09-01'),('Kýþ 2025', '2025-12-01', '2026-02-01'),('Yaz 2024', '2024-06-01', '2024-09-01'),('Kýþ 2024', '2024-12-01', '2025-02-01') ;
-- Urunler
INSERT INTO tblUrunler (UrunKodu, Ad, KategoriID, SezonID) 
VALUES ('V1921NN22CB', 'Yüksek Bel Jean', 1, 1), ('V1921NN22CA', 'Triko Kazak', 3, 3), ('V1921NN22CD', 'V Yaka Kýsa Kollu T-Shirt', 2, 2),('V1921NN22CS', 'Deri Ceket', 4, 4);
-- Stok Kartlari (Variants)
INSERT INTO tblStokKartlari (UrunID, RenkID, BedenID, Barkod)
VALUES 
(1, 3, 2, '8683525933136'),(2, 5, 2, '8683525933132'),(3, 2, 2, '8683525933138'); -- Mavi M Beden Jean (Barkod from your example)
-- Stok Durumu
INSERT INTO tblStokDurum (StokKartID, LokasyonID, Miktar, Raf)
VALUES (1, 1, 100, 'A-12'); -- Depoda 100 tane var





INSERT INTO tblKategoriler (Ad) VALUES ('Pantolon'), ('T-Shirt'), ('Kazak'), ('Ceket'),
('Gömlek'), ('Aksesuar');
-- Renkler
INSERT INTO tblRenkler (Ad, HexKod) VALUES 
('Siyah', '#000000'), ('Beyaz', '#FFFFFF'), ('Mavi', '#0000FF'), ('Kýrmýzý', '#FF0000'), ('Yeþil', '#008000'), 
('Turuncu', '#FFA500'),('Mor', '#800080'), ('Ekru', '#F5F5DC'), ('Gri', '#808080');
-- Bedenler
INSERT INTO tblBedenler (Ad, Sira) VALUES ('XS', 5),  ('XXL', 6),
('S', 2), ('M', 3), ('L', 4), ('XL', 5);
-- Roller
INSERT INTO tblRoller (RolAdi) VALUES ('Müdür'), ('Depo Sorumlusu'), ('Maðaza Personeli'), 
('Admin');
-- Lokasyonlar (Depolar ve Þubeler)
INSERT INTO tblLokasyonlar (Ad, Tur, Mesafe) VALUES 
('Merkez Depo (Ýstanbul)', 'Depo', 0), 
('Ýzmir Merkez Depo', 'Depo', 480),
('Ankara Merkez Depo', 'Depo', 450),
('Alsancak Þubesi', 'Magaza', 485),
('Konak Þubesi', 'Magaza', 482),
('Kadýköy Þubesi', 'Magaza', 15), 
('Beþiktaþ Þubesi', 'Magaza', 20);
-- Personeller
INSERT INTO tblPersoneller (PersonelNo, AdSoyad, Sifre, RolID, LokasyonID, Durum) VALUES 
('1001', 'Umut MUTLU', '12345', 2, 1, 1), -- Depo (Ýstanbul)
('1002', 'Ýpek ÇALIÞKAN', '12345', 2, 2, 1), -- Depo (Ýzmir)
('2001', 'Eda PINAR', '12345', 3, 4, 1), -- Maðaza (Alsancak)
('2002', 'Ayþe YILMAZ', '12345', 3, 6, 1), -- Maðaza (Kadýköy)
('2003', 'Ra SELÝN', '12345', 3, 5, 1), -- Maðaza (Konak)
('9001', 'Ahmet MÜDÜR', 'admin', 1, 1, 1); -- Müdür
-- Sezonlar
INSERT INTO tblSezonlar (Ad, BaslangicTarihi, BitisTarihi) VALUES 
('Yaz 2025', '2025-06-01', '2025-09-01'),
('Sonbahar 2024', '2024-09-01', '2024-12-01'),
('Kýþ 2024', '2024-12-01', '2025-03-01');
-- Tedarikçiler
INSERT INTO tblTedarikciler (FirmaAdi, YetkiliKisi, Telefon) VALUES
('A Firmasý (Tekstil)', 'Mehmet Bey', '05551112233'),
('B Firmasý (Ýplik)', 'Ali Bey', '05552223344'),
('C Firmasý (Lojistik)', 'Veli Bey', '05553334455');
-- Ürünler
INSERT INTO tblUrunler (UrunKodu, Ad, KategoriID, SezonID, Aciklama) VALUES 
('V1921NN22CB', 'Yüksek Bel Ýspanyol Paça Jean Pantolon', 1, 1, 'Pamuklu kumaþ, rahat kesim.'),
('V1921AZ72OP', 'Yüksek Bel Dar Paça Pantolon', 1, 3, 'Likralý, siyah.'),
('V1921AZ22YZ', 'Kýsa Kollu V Yaka T-Shirt', 2, 1, 'Yazlýk, ince kumaþ.'),
('V1921AZ12NM', 'Kaþkorse Viskon Slim Fit Uzun Kollu T-Shirt', 2, 3, 'Kýþlýk içlik olarak da kullanýlýr.'),
('V1820AZ22YZ', 'Oversize Geniþ Kalýp Bisiklet Yaka Triko Kazak', 3, 3, 'Sýcak tutar, yün karýþýmlý.');
-- Stok Kartlari (Variants - Barcodes from user description matching logic where possible)
-- Jean 1 (Mavi)
INSERT INTO tblStokKartlari (UrunID, RenkID, BedenID, Barkod) VALUES 
(1, 3, 2, '8683525933136'), -- Mavi S (Not: Barkodu örnekteki gibi unique daðýttým)
(1, 3, 3, '8683525933136-M'), -- Unique Constraint olduðu için sonuna suffix ekledim, veya farklý barkod girilebilir
(1, 3, 4, '8683525933136-L'), 
(1, 3, 5, '8683525933136-XL');
-- Jean 2 (Siyah)
INSERT INTO tblStokKartlari (UrunID, RenkID, BedenID, Barkod) VALUES 
(2, 1, 2, '8683525933137'), -- Siyah S
(2, 1, 3, '8683525933137-M'),
(2, 1, 4, '8683525933137-L'),
(2, 1, 5, '8683525933137-XL');
-- T-Shirt 1 (Ekru)
INSERT INTO tblStokKartlari (UrunID, RenkID, BedenID, Barkod) VALUES 
(3, 8, 2, '8683525933138'), -- Ekru S
--(3, 8, 3, '8683525933138-M'),
(3, 8, 5, '8683525933138-XL');
-- T-Shirt 2 (Siyah Uzun Kollu)
INSERT INTO tblStokKartlari (UrunID, RenkID, BedenID, Barkod) VALUES 
(4, 1, 4, '8683525933139'), -- Siyah L
(4, 1, 5, '8683525933139-XL');
-- Kazak (Yeþil)
INSERT INTO tblStokKartlari (UrunID, RenkID, BedenID, Barkod) VALUES 
--(5, 5, 4, '8683525933132'), -- Yeþil L
(5, 5, 5, '8683525933132-XL');
-- Stok Durumu (Merkez Depo ve Þubeler)
-- Merkez Depo (Umut'un Yeri)
INSERT INTO tblStokDurum (StokKartID, LokasyonID, Miktar, Raf) VALUES
(1, 1, 50, 'A-12'), (2, 1, 45, 'A-12'), (3, 1, 30, 'A-12'), (4, 1, 20, 'A-12'), -- Jean Mavi S-M-L-XL
(5, 1, 100, 'B-05'), (6, 1, 80, 'B-05'), -- Jean Siyah
(9, 1, 150, 'C-01'), -- T-shirt Ekru S
(13, 1, 10, 'D-02'); -- Kazak Yeþil L (Kritik)
-- Alsancak Þubesi (Eda'nýn Yeri)
INSERT INTO tblStokDurum (StokKartID, LokasyonID, Miktar, Raf) VALUES
(1, 4, 10, 'Reyon-1'), (5, 4, 15, 'Reyon-2'), (9, 4, 20, 'Reyon-3'), (13, 4, 2, 'Reyon-Kýþ');
-- Ýzmir Merkez Depo (Ýpek'in Yeri)
INSERT INTO tblStokDurum (StokKartID, LokasyonID, Miktar, Raf) VALUES
(1, 2, 200, 'Depo-A'), (5, 2, 150, 'Depo-A');
-- Stok Hareketleri (Geçmiþ Ýþlemler)
INSERT INTO tblStokHareketleri (Tarih, StokKartID, IslemTuru, IslemSebebi, Miktar, Raf, GirisLokasyonID, CikisLokasyonID, PersonelID, Aciklama, TedarikciID) VALUES
('2025-12-28 10:00:00', 1, 'Giris', 'Satin Alma', 100, 'A-12', 1, NULL, 1, 'Sezon Öncesi Giriþ', 1),
('2025-12-29 14:30:00', 1, 'Cikis', 'Magazaya Sevk', -20, 'A-12', 4, 1, 1, 'Alsancak Þubesine Gönderim', NULL),
('2025-12-30 09:15:00', 5, 'Sayim', 'Sayim Eksigi', -2, 'B-05', NULL, 1, 1, 'Yýrtýk ürün ayrýldý', NULL),
('2025-12-30 11:45:00', 9, 'Giris', 'Musteri Iadesi', 1, 'C-01', 1, NULL, 3, 'Beden uymadý', NULL),
('2025-12-31 08:00:00', 13, 'Giris', 'Uretimden Giris', 50, 'D-02', 1, NULL, 1, 'Yeni üretim', 2);
-- Sevkiyatlar
INSERT INTO tblSevkiyatlar (SevkiyatNo, CikisLokasyonID, GirisLokasyonID, Durum, OlusturanPersonelID, Aciklama) VALUES
('SVK-2025-001', 1, 4, 'Yolda', 1, 'Yýlbaþý takviyesi'),
('SVK-2025-002', 2, 1, 'Beklemede', 2, 'Merkez depoya transfer');
-- Sevkiyat Detay
INSERT INTO tblSevkiyatDetay (SevkiyatID, StokKartID, Adet, Durum) VALUES
(1, 1, 20, 'Tamam'), (1, 5, 15, 'Tamam'),
(2, 9, 50, 'Hazirlaniyor');
-- Hasar Kayitlari
INSERT INTO tblHasarKayitlari (StokKartID, Adet, HasarTuru, BildirimYeri, PersonelID, Aciklama) VALUES
(5, 1, 'Yýrtýk', 'Depo', 1, 'Paket açýlýrken yýrtýldý');
-- Rezervasyonlar
INSERT INTO tblRezervasyonlar (MusteriID, StokKartID, Adet, Durum, PersonelID, Aciklama) VALUES
(NULL, 1, 1, 'Aktif', 3, 'Akþama gelip alacak'); -- Müþteri ID null olabilir veya "Anonim" müþteri eklenebilir
-- Musteriler
INSERT INTO tblMusteriler (AdSoyad, Telefon) VALUES ('Selin Þekerci', '05559998877');