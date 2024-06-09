use bigdecimal::{num_bigint::Sign, BigDecimal};
use rustler::{BigInt, Encoder, Env, NifMap, NifStruct, NifUntaggedEnum, Term};
use serde::{Deserialize, Deserializer};
use std::collections::HashMap;

#[derive(NifMap)]
struct ParseConfig {}

#[derive(Deserialize, Debug, NifUntaggedEnum)]
#[serde(untagged)]
enum Val {
    Null(Option<()>),
    Bool(bool),
    #[serde(deserialize_with = "deserialize_decimal")]
    Number(Decimal),
    String(String),
    Array(Vec<Val>),
    Object(HashMap<String, Val>),
}

fn deserialize_decimal<'de, D>(deserializer: D) -> Result<Decimal, D::Error>
where
    D: Deserializer<'de>,
{
    BigDecimal::deserialize(deserializer).map(|x| Decimal::from(x))
}

#[derive(NifStruct, Debug)]
#[module = "Decimal"]
pub struct Decimal {
    // the number as an integer
    coef: BigInt,
    // the offset
    exp: i64,
    // only 1 or -1
    sign: i8,
}

impl Decimal {
    pub fn from_int(integer: i64) -> Decimal {
        BigDecimal::from(integer).into()
    }
}

impl From<BigDecimal> for Decimal {
    fn from(big_decimal: BigDecimal) -> Self {
        let sign = match big_decimal.sign() {
            Sign::Plus => 1,
            Sign::Minus => -1,
            Sign::NoSign => 1,
        };

        let (coef, exp) = big_decimal.abs().into_bigint_and_exponent();

        Decimal {
            coef,
            exp: -exp,
            sign,
        }
    }
}

#[rustler::nif]
fn parse<'a>(env: Env<'a>, input: &str, cfg: ParseConfig) -> Result<Val, Term<'a>> {
    match json5::from_str::<Val>(input) {
        Ok(value) => Ok(value),
        Err(err) => Err(err.to_string().encode(env)),
    }
}

#[rustler::nif]
fn make_decimal<'a>(env: Env<'a>, input: &str) -> Result<Decimal, Term<'a>> {
    if let Ok(integer) = input.parse::<BigDecimal>() {
        Ok(Decimal::from(integer))
    } else {
        Err("Invalid decimal".encode(env))
    }
}

rustler::init!("Elixir.Json5RustlerBackend", [parse, make_decimal]);
