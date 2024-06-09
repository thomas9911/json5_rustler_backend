defmodule Json5RustlerBackend.DecodeTestHelper do
  defmacro decimal(input) do
    quote do
      Macro.escape(Decimal.new(unquote(input)))
    end
  end
end

defmodule Json5RustlerBackendTest do
  use ExUnit.Case
  doctest Json5RustlerBackend
  import Json5RustlerBackend.DecodeTestHelper
  require Decimal

  @valid [
    [:null, nil, "null"],
    [:boolean, false, "false"],
    [:boolean, true, "true"],
    ["string single quote", "some text", "'some text'"],
    ["string double quote", "some text", "\"some text\""],
    ["string unicode", "ūňĭčŏďē text", "\"ūňĭčŏďē text\""],
    ["number hex", decimal(2801), "0xaf1"],
    ["number hex", decimal(120_772), "0X1D7c4"],
    [:number, decimal(2801), "2801"],
    [:number, decimal("0.00002"), "2e-5"],
    [:number, decimal(".123"), ".123"],
    [:number, decimal(".123e+7"), "+.123e+7"],
    [:number, decimal("12.123e+7"), "12.123e+7"],
    [:number, decimal(-2801), "-2801"],
    [:number, decimal("-0.00002"), "-2e-5"],
    [:number, decimal("-.123"), "-.123"],
    [:number, decimal("-.123e+7"), "-.123e+7"],
    [:number, decimal("-12.123e+7"), "-12.123e+7"],
    [:array, [], "[]"],
    [:array, [nil], "[null]"],
    [:array, [decimal(1)], "[1]"],
    [:array, [], "[    ]"],
    [:array, [decimal(1), decimal(2), decimal(3)], "[1,2,3]"],
    [:array, [decimal(1), decimal(2), decimal(3)], "[1, 2, 3]"],
    [:array, [decimal(1), decimal(2), decimal(3)], "[1, 2, 3, ]"],
    [:array, [nil, decimal(2)], "[null, 2]"],
    [:array, [nil, decimal(2), "stuff"], "[null, 2 , 'stuff']"],
    [
      :array,
      [nil, decimal(2), "some text"],
      """

      [

       null, 2,

      'some text']

      """
    ],
    [
      :array,
      [
        decimal(1),
        [decimal(2), [decimal(3), [decimal(4), nil]]]
      ],
      """
      [1, [2, [3, [4, null]]]]
      """
    ],
    [
      :comment,
      "text",
      """
      // hallo
      'text'
      """
    ],
    [
      :comment,
      [decimal(1), decimal(2)],
      """
      [1,
      // wauw comment
      2]
      """
    ],
    [
      :multi_line_comment,
      [decimal(1), decimal(2)],
      """
      [1,
      /*

      just some text

      and even more

      */
      2]
      """
    ],
    [
      :multi_line_comment,
      "stuff",
      """
      /*

      just some text

      and even more

      */
      "stuff"
      """
    ],
    [:object, Macro.escape(%{}), "{}"],
    [:object, Macro.escape(%{}), "{    }"],
    [:object, Macro.escape(%{"a" => Decimal.new(1)}), "{a : 1}"],
    [:object, Macro.escape(%{"test" => Decimal.new(1)}), "{test: 1}"],
    [
      :object,
      Macro.escape(%{"test" => Decimal.new(1), "text" => nil}),
      "{test: 1, 'text': null}"
    ],
    [
      :object,
      Macro.escape(%{
        "test" => Decimal.new(1),
        "text" => nil,
        "nested" => %{
          "more" => [Decimal.new(1), Decimal.new(2), Decimal.new(3)],
          "other" => Decimal.new(123)
        },
        "new" => "a keyword"
      }),
      """
      {
        test: 1,
        'text': null,
        "nested": {
          other: 123,
          "more": [1, 2, 3]
        },
        "new": "a keyword"
      }
      """
    ]
    # [
    #   :odd_object,
    #   Macro.escape(%{
    #     "$_" => Decimal.new(1),
    #     "_$" => Decimal.new(2),
    #     ~S"a\u200C" => Decimal.new(3)
    #   }),
    #   ~S"{$_:1,_$:2,a\u200C:3}"
    # ]
  ]

  @doc "We need this because Decimal can have a different format but the value is actually the same"
  def equal?(a, b) when Decimal.is_decimal(a) and Decimal.is_decimal(b) do
    # compare close enough
    Decimal.to_float(a) == Decimal.to_float(b)
  end

  def equal?(a, b) when is_list(a) and is_list(b) do
    a
    |> Enum.zip(b)
    |> Enum.all?(fn {x, y} -> equal?(x, y) end)
  end

  def equal?(a, b) when is_map(a) and is_map(b) do
    a
    |> Enum.sort()
    |> Enum.zip(Enum.sort(b))
    |> Enum.all?(fn {x, y} -> equal?(x, y) end)
  end

  def equal?(a, b) when is_tuple(a) and is_tuple(b) do
    a
    |> Tuple.to_list()
    |> Enum.zip(Tuple.to_list(b))
    |> Enum.all?(fn {x, y} -> equal?(x, y) end)
  end

  def equal?(a, b) do
    a == b
  end

  for [prefix, expected, input] <- @valid do
    test "decode #{prefix} #{input}" do
      {:ok, x} = Json5.decode(unquote(input), backend: Json5RustlerBackend)
      assert equal?(unquote(expected), x)
    end
  end

  describe "decimal" do
    [
      "12.123",
      "0.0",
      "-12.123",
      "1234567890123456789",
      "1.1234545678",
      "0.00000123456",
      "-1.1e27",
      "-1.1e-27",
      "-1.15e-108",
      "-12.123e+7"
    ]
    |> Enum.map(
      fn input ->

        test "#{input}" do
          {:ok, x} = Json5RustlerBackend.make_decimal(unquote(input))
          assert equal?(Decimal.new(unquote(input)), x)
        end

      end
    )
  end
end
