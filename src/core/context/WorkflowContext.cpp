/*!
 * \copyright Copyright (c) 2015 Governikus GmbH & Co. KG
 */

#include "WorkflowContext.h"

using namespace governikus;

WorkflowContext::WorkflowContext()
	: QObject()
	, mStateApproved(false)
	, mCurrentState()
	, mReaderType(ReaderManagerPlugInType::UNKNOWN)
	, mReaderName()
	, mCardConnection()
	, mCan()
	, mPin()
	, mPuk()
	, mPaceOutputData()
	, mOldRetryCounter(-1)
	, mLastPaceResult(CardReturnCode::OK)
	, mStatus(GlobalStatus::Code::No_Error)
	, mErrorReportedToUser(true)
	, mWorkflowFinished(false)
{
}


bool WorkflowContext::isErrorReportedToUser() const
{
	return mErrorReportedToUser;
}


void WorkflowContext::setErrorReportedToUser(bool pErrorReportedToUser)
{
	mErrorReportedToUser = pErrorReportedToUser;
}


void WorkflowContext::setStateApproved(bool pApproved)
{
	if (mStateApproved != pApproved)
	{
		mStateApproved = pApproved;
		Q_EMIT fireStateApprovedChanged();
	}
}


bool WorkflowContext::isStateApproved()
{
	return mStateApproved;
}


const QString& WorkflowContext::getCurrentState() const
{
	return mCurrentState;
}


void WorkflowContext::setCurrentState(const QString& pNewState)
{
	if (mCurrentState != pNewState)
	{
		mCurrentState = pNewState;
		Q_EMIT fireCurrentStateChanged(pNewState);
	}
}


ReaderManagerPlugInType WorkflowContext::getReaderType() const
{
	return mReaderType;
}


void WorkflowContext::setReaderType(ReaderManagerPlugInType pReaderType)
{
	if (mReaderType != pReaderType)
	{
		mReaderType = pReaderType;
		Q_EMIT fireReaderTypeChanged();
	}
}


const QString& WorkflowContext::getReaderName() const
{
	return mReaderName;
}


void WorkflowContext::setReaderName(const QString& pReaderName)
{
	if (mReaderName != pReaderName)
	{
		mReaderName = pReaderName;
		Q_EMIT fireReaderNameChanged();
	}
}


const QSharedPointer<CardConnection>& WorkflowContext::getCardConnection() const
{
	return mCardConnection;
}


void WorkflowContext::setCardConnection(const QSharedPointer<CardConnection>& pCardConnection)
{
	if (mCardConnection != pCardConnection)
	{
		mCardConnection = pCardConnection;
		Q_EMIT fireCardConnectionChanged();
	}
}


bool WorkflowContext::isPinBlocked()
{
	return mCardConnection != nullptr && mCardConnection->getReaderInfo().getRetryCounter() == 0;
}


const QString& WorkflowContext::getPuk() const
{
	return mPuk;
}


void WorkflowContext::setPuk(const QString& pPuk)
{
	if (mPuk != pPuk)
	{
		mPuk = pPuk;
		Q_EMIT firePukChanged();
	}
}


const QString& WorkflowContext::getCan() const
{
	return mCan;
}


void WorkflowContext::setCan(const QString& pCan)
{
	if (mCan != pCan)
	{
		mCan = pCan;
		Q_EMIT fireCanChanged();
	}
}


const QString& WorkflowContext::getPin() const
{
	return mPin;
}


void WorkflowContext::setPin(const QString& pPin)
{
	if (mPin != pPin)
	{
		mPin = pPin;
		Q_EMIT firePinChanged();
	}
}


EstablishPACEChannelOutput* WorkflowContext::getPaceOutputData() const
{
	return mPaceOutputData.data();
}


void WorkflowContext::setPaceOutputData(const EstablishPACEChannelOutput& pPaceOutputData)
{
	mPaceOutputData.reset(new EstablishPACEChannelOutput(pPaceOutputData));
}


CardReturnCode WorkflowContext::getLastPaceResult() const
{
	return mLastPaceResult;
}


int WorkflowContext::getOldRetryCounter() const
{
	return mOldRetryCounter;
}


void WorkflowContext::setLastPaceResultAndRetryCounter(CardReturnCode pLastPaceResult, int pOldRetryCounter)
{
	if (mLastPaceResult != pLastPaceResult || mOldRetryCounter != pOldRetryCounter)
	{
		mLastPaceResult = pLastPaceResult;
		mOldRetryCounter = pOldRetryCounter;
		Q_EMIT fireLastPaceResultChanged();
	}
}


const GlobalStatus& WorkflowContext::getStatus() const
{
	return mStatus;
}


void WorkflowContext::setStatus(const GlobalStatus& pStatus)
{
	mStatus = pStatus;
	mErrorReportedToUser = false;
	Q_EMIT fireResultChanged();
}


bool WorkflowContext::isWorkflowFinished() const
{
	return mWorkflowFinished;
}


void WorkflowContext::setWorkflowFinished(bool pWorkflowFinished)
{
	mWorkflowFinished = pWorkflowFinished;
}
