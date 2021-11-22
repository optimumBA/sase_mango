defmodule SaseMango.PlainTextTableRendererTest do
  use ExUnit.Case, async: true

  alias SaseMango.PlainTextTableRenderer

  test "render/1" do
    data = [
      header: [
        issuer: "Issuer",
        price: "Price",
        nominal_price: "Nominal price",
        ask: "Ask",
        bid: "Bid",
        dividend_roi: "Dividend ROI",
        eps_roi: "EPS ROI",
        pe: "P/E",
        pb: "P/B",
        market_value: "Market Value",
        book_value: "Book Value",
        bvs: "BVS",
        profit_margin: "Profit margin"
      ],
      rows: [
        [
          [
            issuer: "VNRCR",
            ask: "7.00",
            bid: "0.00",
            dividend_roi: "7.08%",
            eps_roi: "95.62%",
            book_value: "3059498",
            bvs: "49.94",
            profit_margin: "8.92%"
          ],
          [
            issuer: "Vinarija Citluk d.d.",
            price: "15.55",
            nominal_price: "100.00",
            pe: "1.05",
            pb: "0.14",
            market_value: "428876"
          ],
          [
            issuer: "ST2",
            ask: "7",
            bid: "0",
            dividend_roi: "3.62%",
            eps_roi: "95.62%",
            book_value: "3298041",
            bvs: "53.83",
            profit_margin: "8.10%"
          ]
        ],
        [
          [
            issuer: "DBJPR",
            ask: "12.00",
            bid: "10.00",
            dividend_roi: "0.00%",
            eps_roi: "28.82%",
            book_value: "9641544",
            bvs: "26.38",
            profit_margin: "8.32%"
          ],
          [
            issuer: "Dobojputevi dd Doboj Jug",
            price: "12.00",
            nominal_price: "10.00",
            pe: "3.47",
            pb: "0.45",
            market_value: "4386624"
          ],
          [
            issuer: "ST2",
            ask: "945",
            bid: "1000",
            dividend_roi: "0.92%",
            eps_roi: "5.41%",
            book_value: "9037524",
            bvs: "24.72",
            profit_margin: "2.03%"
          ]
        ]
      ]
    ]

    assert PlainTextTableRenderer.render(data) == ~S"""
           +--------------------------+-------+---------------+-------+-------+--------------+---------+------+------+--------------+------------+-------+---------------+
           |          Issuer          | Price | Nominal price |  Ask  |  Bid  | Dividend ROI | EPS ROI | P/E  | P/B  | Market Value | Book Value |  BVS  | Profit margin |
           +--------------------------+-------+---------------+-------+-------+--------------+---------+------+------+--------------+------------+-------+---------------+
           |          VNRCR           |       |               | 7.00  | 0.00  |    7.08%     | 95.62%  |      |      |              |  3059498   | 49.94 |     8.92%     |
           |   Vinarija Citluk d.d.   | 15.55 |    100.00     |       |       |              |         | 1.05 | 0.14 |    428876    |            |       |               |
           |           ST2            |       |               |   7   |   0   |    3.62%     | 95.62%  |      |      |              |  3298041   | 53.83 |     8.10%     |
           +--------------------------+-------+---------------+-------+-------+--------------+---------+------+------+--------------+------------+-------+---------------+
           |          DBJPR           |       |               | 12.00 | 10.00 |    0.00%     | 28.82%  |      |      |              |  9641544   | 26.38 |     8.32%     |
           | Dobojputevi dd Doboj Jug | 12.00 |     10.00     |       |       |              |         | 3.47 | 0.45 |   4386624    |            |       |               |
           |           ST2            |       |               |  945  | 1000  |    0.92%     |  5.41%  |      |      |              |  9037524   | 24.72 |     2.03%     |
           +--------------------------+-------+---------------+-------+-------+--------------+---------+------+------+--------------+------------+-------+---------------+
           """
  end

  test "renders empty table" do
    data = [
      header: [
        issuer: "Issuer",
        price: "Price",
        nominal_price: "Nominal price",
        ask: "Ask",
        bid: "Bid",
        dividend_roi: "Dividend ROI",
        eps_roi: "EPS ROI",
        pe: "P/E",
        pb: "P/B",
        market_value: "Market Value",
        book_value: "Book Value",
        bvs: "BVS",
        profit_margin: "Profit margin"
      ],
      rows: []
    ]

    assert PlainTextTableRenderer.render(data) == ~S"""
           +--------+-------+---------------+-----+-----+--------------+---------+-----+-----+--------------+------------+-----+---------------+
           | Issuer | Price | Nominal price | Ask | Bid | Dividend ROI | EPS ROI | P/E | P/B | Market Value | Book Value | BVS | Profit margin |
           +--------+-------+---------------+-----+-----+--------------+---------+-----+-----+--------------+------------+-----+---------------+
           +--------+-------+---------------+-----+-----+--------------+---------+-----+-----+--------------+------------+-----+---------------+
           """
  end
end
