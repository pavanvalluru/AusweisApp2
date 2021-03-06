/*!
 * \copyright Copyright (c) 2015 Governikus GmbH & Co. KG
 */

#include "CardConnectionWorker.h"
#include "pace/PaceHandler.h"

#include <QLoggingCategory>

using namespace governikus;

Q_DECLARE_LOGGING_CATEGORY(card)
Q_DECLARE_LOGGING_CATEGORY(support)

CardConnectionWorker::CardConnectionWorker(Reader* pReader)
	: QObject()
	, QEnableSharedFromThis()
	, mReader(pReader)
	, mSecureMessaging()
{
	connect(this, &CardConnectionWorker::fireRetryCounterPotentiallyChanged, mReader.data(), &Reader::onRetryCounterPotentiallyChanged);
	connect(mReader, &Reader::fireCardInserted, this, &CardConnectionWorker::onReaderInfoChanged);
	connect(mReader, &Reader::fireCardRemoved, this, &CardConnectionWorker::onReaderInfoChanged);
	connect(mReader, &Reader::fireCardRetryCounterChanged, this, &CardConnectionWorker::onReaderInfoChanged);
}


CardConnectionWorker::~CardConnectionWorker()
{
	if (hasCard() && mReader->getCard()->isConnected())
	{
		mReader->getCard()->disconnect();
	}
}


QSharedPointer<CardConnectionWorker> CardConnectionWorker::create(Reader* pReader)
{
	return QSharedPointer<CardConnectionWorker>(new CardConnectionWorker(pReader), &QObject::deleteLater);
}


ReaderInfo CardConnectionWorker::getReaderInfo() const
{
	return mReader.isNull() ? ReaderInfo() : mReader->getReaderInfo();
}


void CardConnectionWorker::setPukInoperative()
{
	mReader->setPukInoperative();
}


bool CardConnectionWorker::hasCard() const
{
	return !mReader.isNull() && mReader->getCard() != nullptr;
}


QSharedPointer<const EFCardAccess> CardConnectionWorker::getEfCardAccess() const
{
	return getReaderInfo().getCardInfo().getEfCardAccess();
}


void CardConnectionWorker::onReaderInfoChanged(const QString& pReaderName)
{
	Q_ASSERT(pReaderName == mReader->getName());
	Q_EMIT fireReaderInfoChanged(mReader->getReaderInfo());
}


CardReturnCode CardConnectionWorker::transmit(const CommandApdu& pCommandApdu, ResponseApdu& pResponseApdu)
{
	if (!hasCard())
	{
		return CardReturnCode::CARD_NOT_FOUND;
	}

	if (mSecureMessaging)
	{
		CommandApdu securedCommandApdu = mSecureMessaging->encrypt(pCommandApdu);
		ResponseApdu securedResponseApdu;
		CardReturnCode returnCode = mReader->getCard()->transmit(securedCommandApdu, securedResponseApdu);
		if (!mSecureMessaging->decrypt(securedResponseApdu, pResponseApdu))
		{
			return CardReturnCode::COMMAND_FAILED;
		}
		return returnCode;
	}
	return mReader->getCard()->transmit(pCommandApdu, pResponseApdu);
}


CardReturnCode CardConnectionWorker::readFile(const FileRef& pFileRef, QByteArray& pFileContent)
{
	if (!hasCard())
	{
		return CardReturnCode::CARD_NOT_FOUND;
	}

	ResponseApdu selectRes;
	CommandApdu select = SelectBuilder(pFileRef).build();
	CardReturnCode returnCode = transmit(select, selectRes);
	if (returnCode != CardReturnCode::OK || selectRes.getReturnCode() != StatusCode::SUCCESS)
	{
		return CardReturnCode::COMMAND_FAILED;
	}

	while (true)
	{
		ResponseApdu res;
		ReadBinaryBuilder rb(static_cast<uint>(pFileContent.count()), 0xff);
		returnCode = transmit(rb.build(), res);
		if (returnCode != CardReturnCode::OK)
		{
			break;
		}

		pFileContent += res.getData();
		if (res.getData().size() != 0xff && res.getReturnCode() == StatusCode::END_OF_FILE)
		{
			return CardReturnCode::OK;
		}
		if (res.getReturnCode() != StatusCode::SUCCESS)
		{
			break;
		}
	}

	return CardReturnCode::COMMAND_FAILED;
}


bool CardConnectionWorker::stopSecureMessaging()
{
	if (mSecureMessaging.isNull())
	{
		return false;
	}

	mSecureMessaging.reset();
	return true;
}


CardReturnCode CardConnectionWorker::establishPaceChannel(PACE_PIN_ID pPinId,
		const QString& pPinValue,
		EstablishPACEChannelOutput& pChannelOutput)
{
	return establishPaceChannel(pPinId, pPinValue, nullptr, nullptr, pChannelOutput);
}


CardReturnCode CardConnectionWorker::establishPaceChannel(PACE_PIN_ID pPinId,
		const QString& pPinValue,
		const QByteArray& pChat,
		const QByteArray& pCertificateDescription,
		EstablishPACEChannelOutput& pChannelOutput)
{
	if (!hasCard())
	{
		return CardReturnCode::CARD_NOT_FOUND;
	}
	CardReturnCode returnCode;

	qCInfo(support) << "Starting PACE for" << pPinId;
	if (mReader->getReaderInfo().isBasicReader())
	{
		Q_ASSERT(!pPinValue.isEmpty());
		PaceHandler paceHandler(sharedFromThis());
		paceHandler.setChat(pChat);
		returnCode = paceHandler.establishPaceChannel(pPinId, pPinValue);

		if (returnCode == CardReturnCode::OK)
		{
			pChannelOutput.setCarCurr(paceHandler.getCarCurr());
			pChannelOutput.setCarPrev(paceHandler.getCarPrev());
			pChannelOutput.setIdIcc(paceHandler.getIdIcc());
			pChannelOutput.setEfCardAccess(getEfCardAccess()->getContentBytes());
			pChannelOutput.setPaceReturnCode(CardReturnCode::OK);
			mSecureMessaging.reset(new SecureMessaging(paceHandler.getPaceProtocol(), paceHandler.getEncryptionKey(), paceHandler.getMacKey()));
		}
	}
	else
	{
		Q_ASSERT(pPinValue.isNull());
		returnCode = mReader->getCard()->establishPaceChannel(pPinId, pChat, pCertificateDescription, pChannelOutput);
	}
	Q_EMIT fireRetryCounterPotentiallyChanged();

	qCInfo(support) << "Finished PACE for" << pPinId << "with result" << returnCode;
	return returnCode;
}


CardReturnCode CardConnectionWorker::destroyPaceChannel()
{
	if (!hasCard())
	{
		return CardReturnCode::CARD_NOT_FOUND;
	}

	qCInfo(support) << "Destroying PACE channel";
	if (mReader->getReaderInfo().isBasicReader())
	{
		stopSecureMessaging();
		MSEBuilder builder(MSEBuilder::P1::ERASE, MSEBuilder::P2::DEFAULT_CHANNEL);
		ResponseApdu response;
		return mReader->getCard()->transmit(builder.build(), response);
	}
	else
	{
		return mReader->getCard()->destroyPaceChannel();
	}
}


CardReturnCode CardConnectionWorker::setEidPin(const QString& pNewPin, quint8 pTimeoutSeconds)
{
	if (!hasCard())
	{
		return CardReturnCode::CARD_NOT_FOUND;
	}

	if (mReader->getReaderInfo().isBasicReader())
	{
		Q_ASSERT(!pNewPin.isEmpty());
		ResetRetryCounterBuilder commandBuilder(pNewPin.toUtf8());
		ResponseApdu response;
		if (transmit(commandBuilder.build(), response) != CardReturnCode::OK || response.getReturnCode() != StatusCode::SUCCESS)
		{
			qCWarning(card) << "Modify PIN failed";
			return CardReturnCode::COMMAND_FAILED;
		}
		return CardReturnCode::OK;
	}
	else
	{
		Q_ASSERT(pNewPin.isEmpty());
		return mReader->getCard()->setEidPin(pTimeoutSeconds);
	}
}


CardReturnCode CardConnectionWorker::updateRetryCounter()
{
	if (!hasCard())
	{
		return CardReturnCode::CARD_NOT_FOUND;
	}
	return mReader->updateRetryCounter(sharedFromThis());
}
